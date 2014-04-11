
BooleanParameter[] previewChannels = new BooleanParameter[NUM_CHANNELS];

int focusedDeck() {
  return lx.engine.focusedDeck.getValuei();
}

final static byte[] APC_MODE_SYSEX = {
  (byte) 0xf0, // sysex start
  (byte) 0x47, // manufacturers id
  (byte) 0x00, // device id
  (byte) 0x73, // product model id
  (byte) 0x60, // message
  (byte) 0x00, // bytes MSB
  (byte) 0x04, // bytes LSB
  (byte) 0x42, // ableton mode 2
  (byte) 0x08, // version maj
  (byte) 0x01, // version min
  (byte) 0x01, // version bugfix
  (byte) 0xf7, // sysex end
};

class MidiEngine {
  
  MPK25 mpk25 = null;
  
  public MidiEngine() {
    setAPC40Mode();
    LXMidiInput apcInput = APC40.matchInput(lx);
    LXMidiOutput apcOutput = APC40.matchOutput(lx);
    LXMidiInput mpkInput = LXMidiSystem.matchInput(lx, "MPK25");
    
    if (apcInput != null) {
      final APC40 apc40 = new APC40(apcInput, apcOutput) {
        protected void noteOn(LXMidiNote note) {
          int channel = note.getChannel();
          switch (note.getPitch()) {
          case APC40.CLIP_LAUNCH:
          case APC40.CLIP_LAUNCH+1:
          case APC40.CLIP_LAUNCH+2:
          case APC40.CLIP_LAUNCH+3:
          case APC40.CLIP_LAUNCH+4:
            uiDeck.selectPattern(note.getChannel(), note.getPitch() - APC40.CLIP_LAUNCH);        
            break;
            
          case APC40.SCENE_LAUNCH:
          case APC40.SCENE_LAUNCH+1:
          case APC40.SCENE_LAUNCH+2:
          case APC40.SCENE_LAUNCH+3:
          case APC40.SCENE_LAUNCH+4:
            uiDeck.selectPattern(focusedDeck(), note.getPitch() - APC40.SCENE_LAUNCH);        
            break;
            
          case APC40.CLIP_STOP:
            if (channel != focusedDeck()) {
              lx.engine.focusedDeck.setValue(channel);
            } else {
              uiDeck.pagePatterns(channel);
            }
            break;
            
          case APC40.MASTER_TRACK:
          case APC40.SHIFT:
            uiDeck.select();
            break;
          case APC40.BANK_UP:
            uiDeck.scroll(-1);
            break;
          case APC40.BANK_DOWN:
            uiDeck.scroll(1);
            break;
          case APC40.BANK_RIGHT:
            lx.engine.focusedDeck.increment();
            break;
          case APC40.BANK_LEFT:
            lx.engine.focusedDeck.decrement();
            break;
          }
        }
        
        protected void controlChange(LXMidiControlChange controller) {
          switch (controller.getCC()) {
          case APC40.CUE_LEVEL:
            uiDeck.knob(controller.getValue());
            break;
          }
        }
      };
      
      int[] channels = new int[NUM_CHANNELS];
      for (int i = 0; i < NUM_CHANNELS; ++i) {
        channels[i] = i;
      }
      
      // Track selection
      apc40.bindNotes(lx.engine.focusedDeck, channels, APC40.TRACK_SELECTION);
      
      // Cue activators
      for (int i = 0; i < NUM_CHANNELS; i++) {
        apc40.bindNote(previewChannels[i], i, APC40.ACTIVATOR, LXMidiDevice.TOGGLE);
      }
      
      for (int i = 0; i < NUM_CHANNELS; i++) {
        final LXDeck deck = lx.engine.getDeck(i);
        deck.addListener(new LXDeck.AbstractListener() {
          public void patternWillChange(LXDeck deck, LXPattern pattern, LXPattern nextPattern) {
            setPattern(apc40, deck);
          }
          public void patternDidChange(LXDeck deck, LXPattern pattern) {
            setPattern(apc40, deck);
          }
        });
        uiDeck.patternLists[deck.index].scrollOffset.addListener(new LXParameterListener() {
          public void onParameterChanged(LXParameter parameter) {
            setPattern(apc40, deck);
          }
        });
        setPattern(apc40, deck);
        TreesTransition transition = getFaderTransition(deck);
        apc40.bindController(deck.getFader(), deck.index, APC40.VOLUME);
        apc40.bindNoteOn(transition.left, deck.index, APC40.SOLO_CUE, LXMidiDevice.TOGGLE);
        apc40.bindNoteOn(transition.right, deck.index, APC40.RECORD_ARM, LXMidiDevice.TOGGLE);
      }
      for (int i = 0; i < 8; ++i) {
        apc40.sendController(0, APC40.TRACK_CONTROL_LED_MODE + i, APC40.LED_MODE_VOLUME);
        apc40.sendController(0, APC40.DEVICE_CONTROL_LED_MODE + i, APC40.LED_MODE_VOLUME);
      }
      
      for (int i = 0; i < 5; ++i) {
        apc40.bindNote(new BooleanParameter("ANON", false), 0, APC40.SCENE_LAUNCH + i, APC40.DIRECT);
      }
      for (int i = 0; i < NUM_CHANNELS; ++i) {
        apc40.bindNote(new BooleanParameter("ANON", false), i, APC40.CLIP_STOP, APC40.DIRECT);
      }
      
      // Master fader
      apc40.bindController(Trees.this.output.brightness, 0, APC40.MASTER_FADER);
      
      // Effect knobs + buttons
      for (int i = 0; i < effectKnobParameters.length; ++i) {
        if (effectKnobParameters[i] != null) {
          apc40.bindController(effectKnobParameters[i], 0, APC40.TRACK_CONTROL + i);
        }
      }
      for (int i = 0; i < effectButtonParameters.length; ++i) {
        apc40.bindNoteOn(effectButtonParameters[i], 0, APC40.PAN + i, LXMidiDevice.TOGGLE);
        apc40.bindNoteOff(effectButtonParameters[i], 0, APC40.PAN + i);
      }
      
      // Pattern control
      apc40.bindDeviceControlKnobs(lx.engine);
      lx.engine.focusedDeck.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          apc40.bindNotes(
            getFaderTransition(lx.engine.getFocusedDeck()).blendMode,
            0,
            new int[] { APC40.CLIP_TRACK, APC40.DEVICE_ON_OFF, APC40.LEFT_ARROW, APC40.RIGHT_ARROW }
          );
        }
      });
      apc40.bindNotes(
        getFaderTransition(lx.engine.getFocusedDeck()).blendMode,
        0,
        new int[] { APC40.CLIP_TRACK, APC40.DEVICE_ON_OFF, APC40.LEFT_ARROW, APC40.RIGHT_ARROW }
      );
      apc40.bindNotes(
        automationSlot,
        0,
        new int[] { APC40.DETAIL_VIEW, APC40.REC_QUANTIZATION, APC40.MIDI_OVERDUB, APC40.METRONOME }
      );
      automationSlot.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setAutomation(apc40);
        }
      });
      setAutomation(apc40);
    }
    
    if (mpkInput != null) {
      mpk25 = new MPK25(mpkInput);
    }
  }
  
  void setAutomation(APC40 apc40) {
    LXAutomationRecorder auto = automation[automationSlot.getValuei()];
    apc40.bindNoteOn(auto.isRunning, 0, APC40.PLAY, LXMidiDevice.TOGGLE);
    apc40.bindNoteOn(auto.armRecord, 0, APC40.REC, LXMidiDevice.TOGGLE);
    apc40.bindNote(automationStop[automationSlot.getValuei()], 0, APC40.STOP, LXMidiDevice.DIRECT);
  }
  
  void setPattern(APC40 apc40, LXDeck deck) {
    int activeIndex = deck.getActivePatternIndex() - uiDeck.patternLists[deck.index].scrollOffset.getValuei();
    int nextIndex = deck.getNextPatternIndex() - uiDeck.patternLists[deck.index].scrollOffset.getValuei();
    for (int i = 0; i < 5; ++i) {
      apc40.sendNoteOn(deck.index, APC40.CLIP_LAUNCH + i, (i == activeIndex) ? APC40.GREEN : ((i == nextIndex) ? APC40.YELLOW : APC40.OFF));
    }
  }
  
  void setAPC40Mode() {
    int i = 0;
    for (String info : de.humatic.mmj.MidiSystem.getOutputs()) { 
      if (info.contains("APC40")) {
        de.humatic.mmj.MidiSystem.openMidiOutput(i).sendMidi(APC_MODE_SYSEX);
        break;
      }
      ++i;
    }
  }
}

interface Drumpad {
  public void padTriggered(int index, int velocity);
  public void padReleased(int index);
}

interface Keyboard {
  public void noteOn(LXMidiNote note);
  public void noteOff(LXMidiNote note);
  public void modWheelChanged(int value);
}

class MPK25 extends LXMidiDevice {
  
  final static int PAD_CHANNEL = 1;
  final static int NUM_PADS = 12;
  final static int PAD1_PITCH = 60;
  final static int PAD2_PITCH = 62;
  final static int PAD3_PITCH = 64;
  final static int PAD4_PITCH = 65;
  final static int PAD5_PITCH = 67;
  final static int PAD6_PITCH = 69;
  final static int PAD7_PITCH = 71;
  final static int PAD8_PITCH = 72;
  final static int PAD9_PITCH = 74;
  final static int PAD10_PITCH = 76;
  final static int PAD11_PITCH = 77;
  final static int PAD12_PITCH = 78;
  
  final int[] PAD_PITCHES = {
    PAD1_PITCH,
    PAD2_PITCH,
    PAD3_PITCH,
    PAD4_PITCH,
    PAD5_PITCH,
    PAD6_PITCH,
    PAD7_PITCH,
    PAD8_PITCH,
    PAD9_PITCH,
    PAD10_PITCH,
    PAD11_PITCH,
    PAD12_PITCH
  };
  
  final static int KEYBOARD_CHANNEL = 1;
  final static int KEYBOARD_PITCH_FIRST = 0;
  final static int KEYBOARD_PITCH_LAST = 120;
  
  final static int MODWHEEL_CHANNEL = 0;
  final static int MODWHEEL_CC = 1;
  
  private Drumpad drumpad = null;
  private Keyboard keyboard = null;
  
  public MPK25(LXMidiInput input) {
    this(input, null);
  }

  public MPK25(LXMidiInput input, LXMidiOutput output) {
    super(input, output);
  }
  
  public void setDrumpad(Drumpad drumpad) {
    this.drumpad = drumpad;
  }
  
  public void setKeyboard(Keyboard keyoard) {
    this.keyboard = keyboard;
  }
  
  private int getPadIndex(LXMidiNote note) {
    if (note.getChannel() == PAD_CHANNEL) {
      for (int i = 0; i < PAD_PITCHES.length; i++) {
        if (note.getPitch() == PAD_PITCHES[i]) {
          return i;
        }
      }
    }
    return -1;
  }
  
  private boolean isKeyboard(LXMidiNote note) {
    return note.getChannel() == KEYBOARD_CHANNEL
        && note.getPitch() >= KEYBOARD_PITCH_FIRST
        && note.getPitch() <= KEYBOARD_PITCH_LAST;
  }
  
  protected void noteOn(LXMidiNote note) {
    if (drumpad != null) {
      int padIndex = getPadIndex(note);
      if (padIndex != -1) {
        drumpad.padTriggered(padIndex, note.getVelocity());
      }
    }
    if (keyboard != null && isKeyboard(note)) {
      keyboard.noteOn(note);
    }
  }

  protected void noteOff(LXMidiNote note) {
    if (drumpad != null) {
      int padIndex = getPadIndex(note);
      if (padIndex != -1) {
        drumpad.padReleased(padIndex);
      }
    }
    if (keyboard != null && isKeyboard(note)) {
      keyboard.noteOff(note);
    }
  }

  protected void controlChange(LXMidiControlChange controlChange) {
    if (keyboard != null && controlChange.getChannel() == MODWHEEL_CHANNEL && controlChange.getCC() == MODWHEEL_CC) {
      keyboard.modWheelChanged(controlChange.getValue());
    }
  }
}

class UIChannelFaders extends UIContext {
  
  final static int SPACER = 30;
  final static int MASTER = 0;
  final static int PADDING = 4;
  final static int BUTTON_HEIGHT = 14;
  final static int FADER_WIDTH = 40;
  final static int WIDTH = SPACER + PADDING + MASTER + (PADDING+FADER_WIDTH)*(NUM_CHANNELS+1);
  final static int HEIGHT = 176;
  
  UIChannelFaders(final UI ui) {
    super(ui, Trees.this.width/2-WIDTH/2, Trees.this.height-HEIGHT-PADDING, WIDTH, HEIGHT);
    setBackgroundColor(#292929);
    setBorderColor(#444444);
    int di = 0;
    final UISlider[] sliders = new UISlider[NUM_CHANNELS];
    final UIButton[] cues = new UIButton[NUM_CHANNELS];
    final UIButton[] lefts = new UIButton[NUM_CHANNELS];
    final UIButton[] rights = new UIButton[NUM_CHANNELS];
    final UILabel[] labels = new UILabel[NUM_CHANNELS];
    for (int i = 0; i < NUM_CHANNELS; i++) {
      final LXDeck deck = lx.engine.getDeck(i);
      float xPos = PADDING + deck.index*(PADDING+FADER_WIDTH) + SPACER;
      
      previewChannels[deck.index] = new BooleanParameter("PRV");
      
      previewChannels[deck.index].addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          cues[deck.index].setActive(previewChannels[deck.index].isOn());
        }
      });
      
      cues[deck.index] = new UIButton(xPos, PADDING, FADER_WIDTH, BUTTON_HEIGHT) {
        void onToggle(boolean active) {
          previewChannels[deck.index].setValue(active);
        }
      };
      cues[deck.index]
      .setActive(previewChannels[deck.index].isOn())
      .addToContainer(this);
      
      lefts[deck.index] = new UIButton(xPos, 2*PADDING+BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT);
      lefts[deck.index]
      .setParameter(getFaderTransition(deck).left)
      .setActiveColor(ui.getSelectionColor())
      .addToContainer(this);
      
      rights[deck.index] = new UIButton(xPos, 3*PADDING+2*BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT);
      rights[deck.index]
      .setParameter(getFaderTransition(deck).right)
      .setActiveColor(#993333)
      .addToContainer(this);
      
      sliders[deck.index] = new UISlider(UISlider.Direction.VERTICAL, xPos, 3*BUTTON_HEIGHT + 4*PADDING, FADER_WIDTH, this.height - 5*BUTTON_HEIGHT - 7*PADDING) {
        public void onFocus() {
          lx.engine.focusedDeck.setValue(deck.index);
        }
      };
      sliders[deck.index]
      .setParameter(deck.getFader())
      .addToContainer(this);
            
      labels[deck.index] = new UILabel(xPos, this.height - 2*PADDING - 2*BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT);
      labels[deck.index]
      .setLabel(shortPatternName(deck.getActivePattern()))
      .setAlignment(CENTER, CENTER)
      .setColor(#999999)
      .setBackgroundColor(#292929)
      .setBorderColor(#666666)
      .addToContainer(this);
      
      deck.addListener(new LXDeck.AbstractListener() {

        void patternWillChange(LXDeck deck, LXPattern pattern, LXPattern nextPattern) {
          labels[deck.index].setLabel(shortPatternName(nextPattern));
          labels[deck.index].setColor(#292929);
          labels[deck.index].setBackgroundColor(#666699);
        }
        
        void patternDidChange(LXDeck deck, LXPattern pattern) {
          labels[deck.index].setLabel(shortPatternName(pattern));
          labels[deck.index].setColor(#999999);
          labels[deck.index].setBackgroundColor(#292929);
        }
      });
      
    }
    
    float xPos = this.width - FADER_WIDTH - PADDING;
    new UISlider(UISlider.Direction.VERTICAL, xPos, PADDING, FADER_WIDTH, this.height-4*PADDING-2*BUTTON_HEIGHT)
    .setParameter(output.brightness)
    .addToContainer(this);
    
    LXParameterListener listener;
    lx.engine.focusedDeck.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        for (int i = 0; i < sliders.length; ++i) {
          sliders[i].setBackgroundColor((i == focusedDeck()) ? ui.getHighlightColor() : #333333);
        }
      }
    });
    listener.onParameterChanged(lx.engine.focusedDeck);
    
    float labelX = PADDING;
    
    new UILabel(labelX, PADDING+2, 0, 0)
    .setColor(#666666)
    .setLabel("CUE")
    .addToContainer(this);
    
    new UILabel(labelX, 2*PADDING+1*BUTTON_HEIGHT+2, 0, 0)
    .setColor(#666666)
    .setLabel("LEFT")
    .addToContainer(this);
    
    new UILabel(labelX, 3*PADDING+2*BUTTON_HEIGHT+2, 0, 0)
    .setColor(#666666)
    .setLabel("RIGHT")
    .addToContainer(this);
    
    new UILabel(labelX, 4*PADDING+3*BUTTON_HEIGHT+6, 0, 0)
    .setColor(#666666)
    .setLabel("LEVEL")
    .addToContainer(this);
    
    new UILabel(labelX, this.height - 2*PADDING - 2*BUTTON_HEIGHT + 3, 0, 0)
    .setColor(#666666)
    .setLabel("PTN")
    .addToContainer(this);
    
    new UILabel(labelX, this.height - PADDING - BUTTON_HEIGHT + 3, 0, 0)
    .setColor(#666666)
    .setLabel("CPU")
    .addToContainer(this);
    
    new UILabel(this.width - PADDING - FADER_WIDTH, this.height-2*PADDING-2*BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT)
    .setColor(#666666)
    .setAlignment(CENTER, CENTER)
    .setLabel("MASTER")
    .addToContainer(this);
    
    new UIPerfMeters()
    .setPosition(SPACER+PADDING, this.height-PADDING-BUTTON_HEIGHT)
    .addToContainer(this);
    
  }
  
  private String shortPatternName(LXPattern pattern) {
    String simpleName = pattern.getClass().getSimpleName(); 
    return simpleName.substring(0, min(7, simpleName.length()));
  }
  
  class UIPerfMeters extends UIObject {
    
    DampedParameter dampers[] = new DampedParameter[NUM_CHANNELS+1];
    BasicParameter perfs[] = new BasicParameter[NUM_CHANNELS+1];
   
    UIPerfMeters() {
      for (int i = 0; i < NUM_CHANNELS+1; ++i) {
        lx.addModulator((dampers[i] = new DampedParameter(perfs[i] = new BasicParameter("PERF", 0), 3)).start());
      }
    } 
    
    public void onDraw(UI ui, PGraphics pg) {
      for (int i = 0; i < NUM_CHANNELS; i++) {
        LXDeck deck = lx.engine.getDeck(i);
        LXPattern pattern = deck.getActivePattern();
        float goMillis = pattern.timer.goNanos / 1000000.;
        float fps60 = 1000 / 60. / 3.;
        perfs[deck.index].setValue(constrain((goMillis-1) / fps60, 0, 1));
      }
      float engMillis = lx.engine.timer.runNanos / 1000000.;
      perfs[NUM_CHANNELS].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
        
      for (int i = 0; i < NUM_CHANNELS + 1; ++i) {
        float val = dampers[i].getValuef();
        pg.stroke(#666666);
        pg.fill(#292929);
        pg.rect(i*(PADDING + FADER_WIDTH), 0, FADER_WIDTH-1, BUTTON_HEIGHT-1); 
        pg.fill(lx.hsb(120*(1-val), 50, 80));
        pg.noStroke();
        pg.rect(i*(PADDING + FADER_WIDTH)+1, 1, val * (FADER_WIDTH-2), BUTTON_HEIGHT-2);
      }
      redraw();
    }
  }
}

public class UIMultiDeck extends UIWindow {

  private final static int KNOBS_PER_ROW = 4;
  
  public final static int DEFAULT_WIDTH = 140;
  public final static int DEFAULT_HEIGHT = 258;

  final UIItemList[] patternLists;
  final UIToggleSet[] blendModes;
  final LXDeck.Listener[] lxListeners;
  final UIKnob[] knobs;

  public UIMultiDeck(UI ui) {
    super(ui, "CHANNEL " + (focusedDeck()+1), Trees.this.width - 4 - DEFAULT_WIDTH, Trees.this.height - 108 - DEFAULT_HEIGHT, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    int yp = TITLE_LABEL_HEIGHT;

    patternLists = new UIItemList[NUM_CHANNELS];
    blendModes = new UIToggleSet[NUM_CHANNELS];
    lxListeners = new LXDeck.Listener[patternLists.length];
    for (int i = 0; i < NUM_CHANNELS; i++) {
      LXDeck deck = lx.engine.getDeck(i);
      List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
      for (LXPattern p : deck.getPatterns()) {
        items.add(new PatternScrollItem(deck, p));
      }
      patternLists[deck.index] = new UIItemList(1, yp, this.width - 2, 100).setItems(items);
      patternLists[deck.index].setVisible(deck.index == focusedDeck());
      patternLists[deck.index].addToContainer(this);      
    }
    
    yp += patternLists[0].getHeight() + 10;
    knobs = new UIKnob[NUM_KNOBS];
    for (int ki = 0; ki < knobs.length; ++ki) {
      knobs[ki] = new UIKnob(5 + 34 * (ki % KNOBS_PER_ROW), yp
        + (ki / KNOBS_PER_ROW) * 48);
      knobs[ki].addToContainer(this);
    }
    
    yp += 100;
    for (int i = 0; i < NUM_CHANNELS; i++) {
      LXDeck deck = lx.engine.getDeck(i);
      blendModes[deck.index] = new UIToggleSet(4, yp, this.width-8, 18)
      .setOptions(new String[] { "ADD", "MLT", "LITE", "SUBT" })
      .setParameter(getFaderTransition(deck).blendMode)
      .setEvenSpacing();
      blendModes[deck.index].setVisible(deck.index == focusedDeck());
      blendModes[deck.index].addToContainer(this);
    }
     
    for (int i = 0; i < NUM_CHANNELS; i++) {
      LXDeck deck = lx.engine.getDeck(i); 
      lxListeners[deck.index] = new LXDeck.AbstractListener() {
        public void patternWillChange(LXDeck deck, LXPattern pattern,
            LXPattern nextPattern) {
          patternLists[deck.index].redraw();
        }

        public void patternDidChange(LXDeck deck, LXPattern pattern) {
          LXPattern[] patterns = deck.getPatterns();
          for (int i = 0; i < patterns.length; ++i) {
            if (patterns[i] == pattern) {
              patternLists[deck.index].setFocusIndex(i);
              break;
            }
          }  
          
          patternLists[deck.index].redraw();
          if (deck.index == focusedDeck()) {
            int pi = 0;
            for (LXParameter parameter : pattern.getParameters()) {
              if (pi >= knobs.length) {
                break;
              }
              if (parameter instanceof LXListenableNormalizedParameter) {
                knobs[pi++].setParameter((LXListenableNormalizedParameter)parameter);
              }
            }
            while (pi < knobs.length) {
              knobs[pi++].setParameter(null);
            }
          }
        }
      };
      deck.addListener(lxListeners[deck.index]);
      lxListeners[deck.index].patternDidChange(deck, deck.getActivePattern());
    }
    
    lx.engine.focusedDeck.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXDeck deck = lx.engine.getDecks().get(focusedDeck()); 
        
        setTitle("CHANNEL " + (deck.index + 1));
        redraw();
        
        lxListeners[deck.index].patternDidChange(deck, deck.getActivePattern());
        
        int pi = 0;
        for (UIItemList patternList : patternLists) {
          patternList.setVisible(pi == focusedDeck());
          ++pi;
        }
        pi = 0;
        for (UIToggleSet blendMode : blendModes) {
          blendMode.setVisible(pi == focusedDeck());
          ++pi;
        }
      }
    });
    
  }
  
  void select() {
    patternLists[focusedDeck()].select();
  }
  
  float amt = 0;
  void knob(int delta) {
    if (delta > 64) {
      delta = delta - 128;
    }
    amt += delta / 4.;
    if (amt > 1) {
      scroll(1);
      amt -= 1;
    } else if (amt < -1) {
      scroll(-1);
      amt += 1;
    }
  }
  
  void selectPattern(int channel, int index) {
    lx.engine.getDeck(channel).goIndex(patternLists[channel].getScrollOffset() + index);
  }
  
  void pagePatterns(int channel) {
    int offset = patternLists[channel].getScrollOffset();
    patternLists[channel].setScrollOffset(offset + 5);
    if (patternLists[channel].getScrollOffset() == offset) {
      patternLists[channel].setScrollOffset(0);
    }
  }
  
  void scroll(int delta) {
    UIItemList list = patternLists[focusedDeck()]; 
    list.setFocusIndex(list.getFocusIndex() + delta);
  } 

  private class PatternScrollItem extends UIItemList.AbstractItem {

    private final LXDeck deck;
    private final LXPattern pattern;

    private final String label;

    PatternScrollItem(LXDeck deck, LXPattern pattern) {
      this.deck = deck;
      this.pattern = pattern;
      this.label = UI.uiClassName(pattern, "Pattern");
    }

    public String getLabel() {
      return this.label;
    }

    public boolean isSelected() {
      return this.deck.getActivePattern() == this.pattern;
    }

    public boolean isPending() {
      return this.deck.getNextPattern() == this.pattern;
    }

    public void onMousePressed() {
      this.deck.goPattern(this.pattern);
    }
  }
}

class UIEffects extends UIWindow {
  
  final int KNOBS_PER_ROW = 4;
  
  UIEffects(UI ui) {
    super(ui, "MASTER EFFECTS", Trees.this.width-144, 110, 140, 120);
    
    int yp = TITLE_LABEL_HEIGHT;
    for (int ki = 0; ki < 8; ++ki) {
      new UIKnob(5 + 34 * (ki % KNOBS_PER_ROW), yp + (ki / KNOBS_PER_ROW) * 48)
      .setParameter(effectKnobParameters[ki])
      .addToContainer(this);
    }
    yp += 98;
    
  } 
  
}

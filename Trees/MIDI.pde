DiscreteParameter focusedChannel = new DiscreteParameter("CHNL", NUM_CHANNELS);
DiscreteParameter previewChannel = new DiscreteParameter("PRV", NUM_CHANNELS+1);
APC40Output apcOutput = null;

final static int VOLUME = 7;
final static int MASTER = 14;
final static int CROSSFADER = 15;

final static int ACTIVATOR = 50;
final static int SOLO_CUE = 49;
final static int RECORD_ARM = 48;
final static int PLAY = 91;
final static int BANK_UP = 94;
final static int BANK_DOWN = 95;
final static int BANK_RIGHT = 96;
final static int BANK_LEFT = 97;
final static int CUE_LEVEL = 47;
final static int CLIP_LAUNCH = 53;
final static int CLIP_STOP = 52;
final static int SCENE_LAUNCH = 82;

final static int SHIFT = 98;

final static int DEVICE_CONTROL = 16;

final static int CLIP_TRACK = 58;
final static int DEVICE_ON_OFF = 59;
final static int LEFT_ARROW = 60;
final static int RIGHT_ARROW = 61;

public class MidiEngine {
  public MidiEngine() {
    previewChannel.setValue(8);
    for (MidiInputDevice mid : RWMidi.getInputDevices()) {
      if (mid.getName().contains("APC40")) {
        new APC40Input(mid);
      }
    }
    for (MidiOutputDevice mid : RWMidi.getOutputDevices()) {
      if (mid.getName().contains("APC40")) {
        apcOutput = new APC40Output(mid);
      }
    }
  }
}

public class APC40Output {
  
  private static final int OFF = 0;
  private static final int GREEN = 1;
  private static final int GREEN_BLINK = 2;
  private static final int RED = 3;
  private static final int RED_BLINK = 4;
  private static final int YELLOW = 5;
  private static final int YELLOW_BLINK = 6;
  
  private final MidiOutput output;
  
  private LXListenableNormalizedParameter[] knobs = new LXListenableNormalizedParameter[NUM_CHANNELS * NUM_KNOBS];
  private final LXParameterListener[] knobListener = new LXParameterListener[NUM_CHANNELS * NUM_KNOBS];
  
  public APC40Output(MidiOutputDevice device) {
    this.output = device.createOutput();
    
    for (int i = 0; i < knobListener.length; ++i) {
      final int channel = i / NUM_KNOBS;
      final int cc = 16 + (i % NUM_KNOBS);
      knobListener[i] = new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          int normalized = (int) (127. * ((LXNormalizedParameter)parameter).getNormalized());
          output.sendController(channel, cc, normalized);
        }
      };
    }
    
    for (int i = 0; i < knobs.length; ++i) {
      knobs[i] = null;
    }
    
    for (final LXDeck deck : lx.engine.getDecks()) {
      final TreesTransition t = getFaderTransition(deck); 
      t.blendMode.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setBlendMode(deck);
        }
      });
      t.left.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setLeft(deck.index, t.left.isOn());
        }
      });
      t.right.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setRight(deck.index, t.right.isOn());
        }
      });
      deck.addListener(new LXDeck.AbstractListener() {
        public void patternWillChange(LXDeck deck, LXPattern pattern, LXPattern nextPattern) {
          setPattern(deck);
        }
        public void patternDidChange(LXDeck deck, LXPattern pattern) {
          setKnobs(deck);
          setPattern(deck);
        }
      });
      uiDeck.patternLists[deck.index].scrollOffset.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setPattern(deck);
        }
      });
      setPattern(deck);
      setKnobs(deck);
      setBlendMode(deck);
      setLeft(deck.index, t.left.isOn());
      setRight(deck.index, t.right.isOn());
    }
    
    previewChannel.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        setCueButtons();
      }
    });
    setCueButtons();
  }
  
  void setPattern(LXDeck deck) {
    int activeIndex = deck.getActivePatternIndex() - uiDeck.patternLists[deck.index].scrollOffset.getValuei();
    int nextIndex = deck.getNextPatternIndex() - uiDeck.patternLists[deck.index].scrollOffset.getValuei();
    for (int i = 0; i < 5; ++i) {
      output.sendNoteOn(deck.index, CLIP_LAUNCH + i, (i == activeIndex) ? GREEN : ((i == nextIndex) ? YELLOW : OFF));
    }
  }
  
  private void setLeft(int channel, boolean on) {
    output.sendNoteOn(channel, SOLO_CUE, on ? GREEN : OFF);
  }
  
  private void setRight(int channel, boolean on) {
    output.sendNoteOn(channel, RECORD_ARM, on ? GREEN : OFF);
  }
  
  private void setCueButtons() {
    for (int i = 0; i < NUM_CHANNELS; ++i) {
      output.sendNoteOn(i, ACTIVATOR, (previewChannel.getValuei() == i) ? GREEN : OFF);
    }
  }
  
  void setBlendMode(LXDeck deck) {
    int blendv = getFaderTransition(deck).blendMode.getValuei();
    for (int note = CLIP_TRACK; note <= RIGHT_ARROW; ++note) {
      output.sendNoteOn(deck.index, note, (blendv == (note-CLIP_TRACK)) ? GREEN : OFF);
    }
  }
  
  private void setKnobs(LXDeck deck) {
    for (int k = 0; k < NUM_KNOBS; ++k) {
      int i = NUM_KNOBS*deck.index + k;
      if (knobs[i] != null) {
        knobs[i].removeListener(knobListener[i]);
        knobs[i] = null;
      }
    }  
    int pi = 0;
    for (LXParameter parameter : deck.getActivePattern().getParameters()) {
      if (parameter instanceof LXListenableNormalizedParameter) {
        int i = NUM_KNOBS*deck.index + pi; 
        knobs[i] = (LXListenableNormalizedParameter)parameter;
        knobs[i].addListener(knobListener[i]);
        int value = (int) (127. * knobs[i].getNormalized());
        output.sendController(deck.index, DEVICE_CONTROL+pi, value);
        if (++pi >= NUM_KNOBS) {
          break;
        }
      }
    }
    while (pi < NUM_KNOBS) {
      output.sendController(deck.index, DEVICE_CONTROL+pi, 0);
      ++pi;
    }
  }
}


public class APC40Input {
  
  private boolean shiftPressed = false;
  
  public APC40Input(MidiInputDevice device) {
    device.createInput(this);
  }
  
  private void setSlider(LXNormalizedParameter slider, float normalized) {
    if (abs(normalized - slider.getNormalizedf()) < 0.25) {
      slider.setNormalized(normalized);
    }
  } 
  
  public void controllerChangeReceived(rwmidi.Controller controller) {
    int cc = controller.getCC();
    int channel = controller.getChannel();
    int value = controller.getValue();
    float normalized = value / 127.;
    switch (cc) {
    case VOLUME:
      if (channel < NUM_CHANNELS) {
        setSlider(lx.engine.getDeck(channel).getFader(), normalized);
      }
      break;
    case MASTER:
      setSlider(output.brightness, normalized);
      break;
    case CROSSFADER:
      setSlider(crossfader, normalized);
      break;
    
    case DEVICE_CONTROL:
    case DEVICE_CONTROL+1:
    case DEVICE_CONTROL+2:
    case DEVICE_CONTROL+3:
    case DEVICE_CONTROL+4:
    case DEVICE_CONTROL+5:
    case DEVICE_CONTROL+6:
    case DEVICE_CONTROL+7:
      if (channel < NUM_CHANNELS) {
        focusedChannel.setValue(channel);
        int paramNum = cc - DEVICE_CONTROL;
        int pi = 0;
        for (LXParameter parameter : lx.engine.getDeck(channel).getActivePattern().getParameters()) {
          if (parameter instanceof LXListenableNormalizedParameter) {
            if (pi == paramNum) {
              ((LXListenableNormalizedParameter) parameter).setNormalized(normalized);
              break;
            }
            ++pi;
          }
        }
      }
      break;
      
    case CUE_LEVEL:
      uiDeck.knob(value);
      break;
      
    default:
      println("cc:" + cc);
    }
  }
  
  public void noteOnReceived(Note note) {
    int channel = note.getChannel();
    int number = note.getPitch();
    switch (number) {
      case SHIFT:
        shiftPressed = true;
        break;
      
      case ACTIVATOR:
        previewChannel.setValue(channel);
        break;
      case SOLO_CUE:
        getFaderTransition(lx.engine.getDeck(channel)).left.setValue(true);
        break;
      case RECORD_ARM:
        getFaderTransition(lx.engine.getDeck(channel)).right.setValue(true);
        break;
      
      case CLIP_LAUNCH:
      case CLIP_LAUNCH+1:
      case CLIP_LAUNCH+2:
      case CLIP_LAUNCH+3:
      case CLIP_LAUNCH+4:
        uiDeck.selectPattern(channel, number - CLIP_LAUNCH);        
        break;
        
      case SCENE_LAUNCH:
      case SCENE_LAUNCH+1:
      case SCENE_LAUNCH+2:
      case SCENE_LAUNCH+3:
      case SCENE_LAUNCH+4:
        uiDeck.selectPattern(focusedChannel.getValuei(), number - SCENE_LAUNCH);        
        break;
        
      case CLIP_STOP:
        uiDeck.pagePatterns(channel);
        break;
      
      case CLIP_TRACK:
      case DEVICE_ON_OFF:
      case LEFT_ARROW:
      case RIGHT_ARROW:
        if (channel < NUM_CHANNELS) {
          getFaderTransition(lx.engine.getDeck(channel)).blendMode.setValue(number - CLIP_TRACK);
        }
        break;
        
      case PLAY:
        uiDeck.select();
        break;
      case BANK_UP:
        uiDeck.scroll(-1);
        break;
      case BANK_DOWN:
        uiDeck.scroll(1);
        break;
      case BANK_RIGHT:
        focusedChannel.increment();
        break;
      case BANK_LEFT:
        focusedChannel.decrement();
        break;
      default:
        println("noteOn: " + note);
        break;
    }
  }
  
  public void noteOffReceived(Note note) {
    int channel = note.getChannel();
    int number = note.getPitch();
    switch (number) {
      case SHIFT:
        shiftPressed = false;
        break;
      
      case RECORD_ARM:
        getFaderTransition(lx.engine.getDeck(channel)).right.setValue(false);
        break;
      case SOLO_CUE:
        getFaderTransition(lx.engine.getDeck(channel)).left.setValue(false);
        break;
      case ACTIVATOR:
        previewChannel.setValue(NUM_CHANNELS);
        break;
        
      case CLIP_LAUNCH:
      case CLIP_LAUNCH+1:
      case CLIP_LAUNCH+2:
      case CLIP_LAUNCH+3:
      case CLIP_LAUNCH+4:
        if (apcOutput != null) {
          apcOutput.setPattern(lx.engine.getDeck(channel));
        }
        break;
        
      case CLIP_STOP:
        break;
        
      case CLIP_TRACK:
      case DEVICE_ON_OFF:
      case LEFT_ARROW:
      case RIGHT_ARROW:
        if (channel < NUM_CHANNELS) {
          getFaderTransition(lx.engine.getDeck(channel)).blendMode.setValue(number - CLIP_TRACK);
        }
        if (apcOutput != null) {
          apcOutput.setBlendMode(lx.engine.getDeck(channel));
        }
        break;
        
      case PLAY:
      case BANK_UP:
      case BANK_DOWN:
      case BANK_RIGHT:
      case BANK_LEFT:
        break;
      
      default:
        println("noteOff: " + note);
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
  final static int HEIGHT = 168;
  
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
    for (final LXDeck deck : lx.engine.getDecks()) {
      float xPos = PADDING + deck.index*(PADDING+FADER_WIDTH) + SPACER;
      
      cues[deck.index] = new UIButton(xPos, PADDING, FADER_WIDTH, BUTTON_HEIGHT) {
        void onToggle(boolean active) {
          if (active) {
            previewChannel.setValue(deck.index);
          } else {
            previewChannel.setValue(8);
          }
        }
      };
      cues[deck.index]
      .setActive(deck.index == previewChannel.getValuei())
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
      
      sliders[deck.index] = new UISlider(UISlider.Direction.VERTICAL, xPos, 3*BUTTON_HEIGHT + 4*PADDING, FADER_WIDTH, this.height - 4*BUTTON_HEIGHT - 6*PADDING) {
        public void onFocus() {
          focusedChannel.setValue(deck.index);
        }
      };
      sliders[deck.index]
      .setParameter(deck.getFader())
      .addToContainer(this);
            
      labels[deck.index] = new UILabel(xPos, this.height - PADDING - BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT);
      labels[deck.index]
      .setLabel(shortPatternName(deck.getActivePattern()))
      .setAlignment(CENTER, CENTER)
      .setBackgroundColor(#292929)
      .setBorderColor(#666666)
      .addToContainer(this);
      
      deck.addListener(new LXDeck.AbstractListener() {
        void patternDidChange(LXDeck deck, LXPattern pattern) {
          labels[deck.index].setLabel(shortPatternName(pattern));
        }
      });
      
    }
    
    float xPos = this.width - FADER_WIDTH - PADDING;
    new UISlider(UISlider.Direction.VERTICAL, xPos, PADDING, FADER_WIDTH, this.height-3*PADDING-BUTTON_HEIGHT)
    .setParameter(output.brightness)
    .addToContainer(this);
    
    previewChannel.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        int channel = previewChannel.getValuei();
        for (int i = 0; i < cues.length; ++i) {
          cues[i].setActive(i == channel);
        }
        previewChannel.setValue(channel);
      }
    });
    
    LXParameterListener listener;
    focusedChannel.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        for (int i = 0; i < sliders.length; ++i) {
          sliders[i].setBackgroundColor((i == focusedChannel.getValuei()) ? ui.getHighlightColor() : #333333);
        }
      }
    });
    listener.onParameterChanged(focusedChannel);
    
    float labelX = PADDING;
    
    new UILabel(labelX, PADDING+1, 0, 0)
    .setColor(#666666)
    .setLabel("PTN")
    .addToContainer(this);
    
    
    new UILabel(labelX, 2*PADDING+BUTTON_HEIGHT+1, 0, 0)
    .setColor(#666666)
    .setLabel("CUE")
    .addToContainer(this);
    
    new UILabel(labelX, 3*PADDING+2*BUTTON_HEIGHT+1, 0, 0)
    .setColor(#666666)
    .setLabel("LEFT")
    .addToContainer(this);
    
    new UILabel(labelX, 4*PADDING+3*BUTTON_HEIGHT+1, 0, 0)
    .setColor(#666666)
    .setLabel("RIGHT")
    .addToContainer(this);
    
    new UILabel(labelX, this.height/2, 0, 0)
    .setColor(#666666)
    .setLabel("LEVEL")
    .addToContainer(this);
    
    new UILabel(this.width - PADDING - FADER_WIDTH, this.height-PADDING-BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT)
    .setColor(#666666)
    .setAlignment(CENTER, CENTER)
    .setLabel("MASTER")
    .addToContainer(this);
    
  }
  
  private String shortPatternName(LXPattern pattern) {
    return pattern.getClass().getSimpleName().substring(0, 5);
  }
}

public class UICrossfader extends UIContext {
  UICrossfader(UI ui) {
    super(ui, (Trees.this.width - UIChannelFaders.WIDTH)/2, Trees.this.height - 40, UIChannelFaders.WIDTH, 36);
    setBackgroundColor(#292929);
    setBorderColor(#444444);
    
    final int CF_WIDTH = 128;
    new UISlider((this.width - CF_WIDTH - UIChannelFaders.FADER_WIDTH - 4 - UIChannelFaders.MASTER)/2, 4, CF_WIDTH, this.height-8)
    .setParameter(crossfader)
    .setBorder(false)
    .addToContainer(this);
  }
}

public class UIMultiDeck extends UIWindow {

  private final static int KNOBS_PER_ROW = 4;
  
  public final static int DEFAULT_WIDTH = 140;
  public final static int DEFAULT_HEIGHT = 260;

  final UIItemList[] patternLists;
  final UIToggleSet[] blendModes;
  final LXDeck.Listener[] lxListeners;
  final UIKnob[] knobs;

  public UIMultiDeck(UI ui) {
    super(ui, "CHANNEL " + (focusedChannel.getValuei()+1), Trees.this.width - 4 - DEFAULT_WIDTH, Trees.this.height - 4 - DEFAULT_HEIGHT, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    int yp = TITLE_LABEL_HEIGHT;

    patternLists = new UIItemList[lx.engine.getDecks().size()];
    blendModes = new UIToggleSet[lx.engine.getDecks().size()];
    lxListeners = new LXDeck.Listener[patternLists.length];
    for (LXDeck deck : lx.engine.getDecks()) {
      List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
      for (LXPattern p : deck.getPatterns()) {
        items.add(new PatternScrollItem(deck, p));
      }
      patternLists[deck.index] = new UIItemList(1, yp, this.width - 2, 100).setItems(items);
      patternLists[deck.index].setVisible(deck.index == focusedChannel.getValuei());
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
    for (LXDeck deck : lx.engine.getDecks()) {
      blendModes[deck.index] = new UIToggleSet(4, yp, this.width-8, 18)
      .setOptions(new String[] { "ADD", "MLT", "LITE", "LERP" })
      .setParameter(getFaderTransition(deck).blendMode)
      .setEvenSpacing();
      blendModes[deck.index].setVisible(deck.index == focusedChannel.getValuei());
      blendModes[deck.index].addToContainer(this);
    }
     
    for (LXDeck deck : lx.engine.getDecks()) {  
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
          if (deck.index == focusedChannel.getValuei()) {
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
    
    focusedChannel.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXDeck deck = lx.engine.getDecks().get(focusedChannel.getValuei()); 
        
        setTitle("CHANNEL " + (deck.index + 1));
        redraw();
        
        lxListeners[deck.index].patternDidChange(deck, deck.getActivePattern());
        
        int pi = 0;
        for (UIItemList patternList : patternLists) {
          patternList.setVisible(pi == focusedChannel.getValuei());
          ++pi;
        }
        pi = 0;
        for (UIToggleSet blendMode : blendModes) {
          blendMode.setVisible(pi == focusedChannel.getValuei());
          ++pi;
        }
      }
    });
    
  }
  
  void select() {
    patternLists[focusedChannel.getValuei()].select();
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
    UIItemList list = patternLists[focusedChannel.getValuei()]; 
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


DiscreteParameter focusedChannel = new DiscreteParameter("CHNL", NUM_CHANNELS);
DiscreteParameter previewChannel = new DiscreteParameter("PRV", NUM_CHANNELS+1);
APC40Output apcOutput = null;

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
      setKnobs(deck);
      setTransition(deck);
      getFaderTransition(deck).blendMode.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          setTransition(deck);
        }
      });
      deck.addListener(new LXDeck.AbstractListener() {
        public void patternDidChange(LXDeck deck, LXPattern pattern) {
          setKnobs(deck);
        }
      });
    }
    
    previewChannel.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        setCueButtons();
      }
    });
    setCueButtons();
  }
  
  private void setCueButtons() {
    for (int i = 0; i < NUM_CHANNELS; ++i) {
      for (int note = 48; note <= 50; ++note) {
        output.sendNoteOn(i, note, (previewChannel.getValuei() == i) ? GREEN : OFF);
      }
    }
  }
  
  void setTransition(LXDeck deck) {
    int blendv = getFaderTransition(deck).blendMode.getValuei();
    for (int note = 58; note <= 61; ++note) {
      output.sendNoteOn(deck.index, note, (blendv == (note-58)) ? GREEN : OFF);
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
        output.sendController(deck.index, 16+pi, value);
        if (++pi >= NUM_KNOBS) {
          break;
        }
      }
    }
    while (pi < NUM_KNOBS) {
      output.sendController(deck.index, 16+pi, 0);
      ++pi;
    }
  }
}


public class APC40Input {
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
    case 7:
      if (channel < NUM_CHANNELS) {
        setSlider(lx.engine.getDeck(channel).getFader(), normalized);
      }
      break;
    case 14:
      setSlider(output.brightness, normalized);
      break;
    case 15:
      setSlider(crossfader, normalized);
      break;
    case 16:
    case 17:
    case 18:
    case 19:
    case 20:
    case 21:
    case 22:
    case 23:
      if (channel < NUM_CHANNELS) {
        focusedChannel.setValue(channel);
        int paramNum = cc - 16;
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
      
    case 47:
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
      case 48:
      case 49:
      case 50:
        previewChannel.setValue(channel);
        break;
        
      case 58:
      case 59:
      case 60:
      case 61:
        if (channel < NUM_CHANNELS) {
          getFaderTransition(lx.engine.getDeck(channel)).blendMode.setValue(number - 58);
        }
        break;
        
      case 91:
        uiDeck.select();
        break;
      case 94:
        uiDeck.scroll(-1);
        break;
      case 95:
        uiDeck.scroll(1);
        break;
      case 96:
        focusedChannel.increment();
        break;
      case 97:
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
      case 48:
      case 49:
      case 50:
        previewChannel.setValue(NUM_CHANNELS);
        break;
        
      case 58:
      case 59:
      case 60:
      case 61:
        if (channel < NUM_CHANNELS) {
          getFaderTransition(lx.engine.getDeck(channel)).blendMode.setValue(number - 58);
        }
        if (apcOutput != null) {
          apcOutput.setTransition(lx.engine.getDeck(channel));
        }
        break;
        
      case 91:
      case 94:
      case 95:
      case 96:
      case 97:
        break;
      default:
        println("noteOff: " + note);
    }
  }
  
}

class UIChannelFaders extends UIContext {
  
  final static int SPACER = 24;
  final static int MASTER = 8;
  final static int PADDING = 4;
  final static int FADER_WIDTH = 40;
  final static int WIDTH = SPACER + PADDING + MASTER + (PADDING+FADER_WIDTH)*(NUM_CHANNELS+1);
  final static int HEIGHT = 108;
  
  UIChannelFaders(final UI ui) {
    super(ui, Trees.this.width/2-WIDTH/2, Trees.this.height-HEIGHT-44, WIDTH, HEIGHT);
    setBackgroundColor(#292929);
    setBorderColor(#444444);
    int di = 0;
    final UISlider[] sliders = new UISlider[NUM_CHANNELS];
    final UIButton[] cues = new UIButton[NUM_CHANNELS];
    final UILabel[] labels = new UILabel[NUM_CHANNELS];
    for (final LXDeck deck : lx.engine.getDecks()) {
      float xPos = PADDING + deck.index*(PADDING+FADER_WIDTH) + ((deck.index >= 4) ? SPACER : 0);
      
      cues[deck.index] = new UIButton(xPos, PADDING, FADER_WIDTH, 12) {
        void onToggle(boolean active) {
          if (active) {
            previewChannel.setValue(deck.index);
          } else {
            previewChannel.setValue(8);
          }
        }
      };
      cues[deck.index]
      .setActiveColor(#993333)
      .setActive(deck.index == previewChannel.getValuei())
      .addToContainer(this);
      
      sliders[deck.index] = new UISlider(UISlider.Direction.VERTICAL, xPos, PADDING + 14, FADER_WIDTH, this.height - 36) {
        public void onFocus() {
          focusedChannel.setValue(deck.index);
        }
      };
      sliders[deck.index]
      .setParameter(deck.getFader())
      .addToContainer(this);
            
      labels[deck.index] = new UILabel(xPos, this.height - PADDING - 12, FADER_WIDTH, 12);
      labels[deck.index]
      .setLabel(shortPatternName(deck.getActivePattern()))
      .setPadding(2)
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
    new UISlider(UISlider.Direction.VERTICAL, xPos, PADDING, FADER_WIDTH, this.height-22)
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
    
    float labelX = (this.width - FADER_WIDTH - PADDING - MASTER) / 2.;
    new UILabel(labelX, PADDING+1, 0, 0)
    .setAlignment(CENTER, TOP)
    .setColor(#666666)
    .setLabel("CUE")
    .addToContainer(this);
    
    new UILabel(labelX, this.height/2, 0, 0)
    .setAlignment(CENTER, CENTER)
    .setColor(#666666)
    .setLabel("LVL")
    .addToContainer(this);
    
    new UILabel(labelX, this.height-14, 0, 0)
    .setAlignment(CENTER, TOP)
    .setColor(#666666)
    .setLabel("PTN")
    .addToContainer(this);
    
    new UILabel(this.width - PADDING - FADER_WIDTH, this.height-16, FADER_WIDTH, 12)
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
  public final static int DEFAULT_HEIGHT = 274;

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
    
    yp += 98;
    for (LXDeck deck : lx.engine.getDecks()) {
      blendModes[deck.index] = new UIToggleSet(4, yp, this.width-8, 20)
      .setOptions(new String[] { "ADD", "MLT", "LITE", "LRP" })
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


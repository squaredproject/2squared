
BooleanParameter[] previewChannels = new BooleanParameter[NUM_CHANNELS];

int focusedChannel() {
  return lx.engine.focusedChannel.getValuei();
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

boolean isMPK25Connected() {
    try {
        return LXMidiSystem.matchInput(lx, "MPK25") != null;
    } catch (java.lang.UnsatisfiedLinkError e){
        return false;
    }
}

class MidiEngine {
  
  MPK25 mpk25 = null;
  
  public MidiEngine() {
    try{
        setAPC40Mode();
    } catch (java.lang.UnsatisfiedLinkError e){
        return;
    }
    LXMidiInput apcInput = APC40.matchInput(lx);
    LXMidiOutput apcOutput = APC40.matchOutput(lx);
    LXMidiInput mpkInput = LXMidiSystem.matchInput(lx, "MPK25");
    
    if (apcInput != null) {
      final APC40 apc40 = new APC40(apcInput, apcOutput) {
        protected void noteOn(LXMidiNoteOn note) {
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
            uiDeck.selectPattern(focusedChannel(), note.getPitch() - APC40.SCENE_LAUNCH);        
            break;
            
          case APC40.CLIP_STOP:
            if (channel != focusedChannel()) {
              lx.engine.focusedChannel.setValue(channel);
            } else {
              uiDeck.pagePatterns(channel);
            }
            break;
            
          case APC40.SOLO_CUE:
            if (previewChannels[channel].isOn() && channel != focusedChannel()) {
              lx.engine.focusedChannel.setValue(channel);
            }
            break;
            
          case APC40.SEND_A:
            bpmTool.beatType.increment();
            break;
          case APC40.SEND_B:
            bpmTool.tempoLfoType.increment();
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
            lx.engine.focusedChannel.increment();
            break;
          case APC40.BANK_LEFT:
            lx.engine.focusedChannel.decrement();
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
      apc40.bindNotes(lx.engine.focusedChannel, channels, APC40.TRACK_SELECTION);
      
      // Cue activators
      for (int i = 0; i < NUM_CHANNELS; i++) {
        apc40.bindNote(previewChannels[i], i, APC40.SOLO_CUE, LXMidiDevice.TOGGLE);
      }
      
      for (int i = 0; i < NUM_CHANNELS; i++) {
        final LXChannel channel = lx.engine.getChannel(i);
        channel.addListener(new LXChannel.AbstractListener() {
          public void patternWillChange(LXChannel channel, LXPattern pattern, LXPattern nextPattern) {
            setPattern(apc40, channel);
          }
          public void patternDidChange(LXChannel channel, LXPattern pattern) {
            setPattern(apc40, channel);
          }
        });
        uiDeck.patternLists[channel.getIndex()].scrollOffset.addListener(new LXParameterListener() {
          public void onParameterChanged(LXParameter parameter) {
            setPattern(apc40, channel);
          }
        });
        setPattern(apc40, channel);
        TreesTransition transition = getFaderTransition(channel);
        apc40.bindController(channel.getFader(), channel.getIndex(), APC40.VOLUME, LXMidiDevice.TakeoverMode.PICKUP);
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
      apc40.bindController(Trees.this.output.brightness, 0, APC40.MASTER_FADER, LXMidiDevice.TakeoverMode.PICKUP);
      
      // Effect knobs + buttons
      for (int i = 0; i < effectKnobParameters.length; ++i) {
        if (effectKnobParameters[i] != null) {
          apc40.bindController(effectKnobParameters[i], 0, APC40.TRACK_CONTROL + i);
        }
      }
      
      // Pattern control
      apc40.bindDeviceControlKnobs(lx.engine);
      lx.engine.focusedChannel.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          apc40.bindNotes(
            getFaderTransition(lx.engine.getFocusedChannel()).blendMode,
            0,
            new int[] { APC40.CLIP_TRACK, APC40.DEVICE_ON_OFF, APC40.LEFT_ARROW, APC40.RIGHT_ARROW }
          );
        }
      });
      
      // Tap Tempo
      apc40.bindNote(new BooleanParameter("ANON", false), 0, APC40.SEND_A, APC40.DIRECT);
      apc40.bindNote(new BooleanParameter("ANON", false), 0, APC40.SEND_B, APC40.DIRECT);
      apc40.bindNote(bpmTool.addTempoLfo, 0, APC40.PAN, APC40.DIRECT);
      apc40.bindNote(bpmTool.clearAllTempoLfos, 0, APC40.SEND_C, APC40.DIRECT);
      apc40.bindNote(bpmTool.tapTempo, 0, APC40.TAP_TEMPO, APC40.DIRECT);
      apc40.bindNote(bpmTool.nudgeUpTempo, 0, APC40.NUDGE_PLUS, APC40.DIRECT);
      apc40.bindNote(bpmTool.nudgeDownTempo, 0, APC40.NUDGE_MINUS, APC40.DIRECT);
      
      apc40.bindNotes(
        getFaderTransition(lx.engine.getFocusedChannel()).blendMode,
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
  
  void setPattern(APC40 apc40, LXChannel channel) {
    int activeIndex = channel.getActivePatternIndex() - uiDeck.patternLists[channel.getIndex()].scrollOffset.getValuei();
    int nextIndex = channel.getNextPatternIndex() - uiDeck.patternLists[channel.getIndex()].scrollOffset.getValuei();
    for (int i = 0; i < 5; ++i) {
      apc40.sendNoteOn(channel.getIndex(), APC40.CLIP_LAUNCH + i, (i == activeIndex) ? APC40.GREEN : ((i == nextIndex) ? APC40.YELLOW : APC40.OFF));
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
  public void noteOn(LXMidiNoteOn note);
  public void noteOff(LXMidiNoteOff note);
  public void modWheelChanged(float value);
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
  
  final static int KEYBOARD_CHANNEL = 0;
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
  
  public void setKeyboard(Keyboard keyboard) {
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
  
  protected void noteOn(LXMidiNoteOn note) {
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

  protected void noteOff(LXMidiNoteOff note) {
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
      keyboard.modWheelChanged(controlChange.getValue() / 127.);
    }
  }
}


class TSKeyboard implements Keyboard {
  
  KeyboardPlayablePattern[] patterns = null;
  LXChannel channel = null;
  
  void configure(LX lx) {
    patterns = new KeyboardPlayablePattern[] {
      new Explosions(lx),
    };
    
    LXPattern[] lxPatterns = new LXPattern[patterns.length];
    for (int i = 0; i < patterns.length; i++) {
      lxPatterns[i] = (LXPattern)patterns[i]; // trust they extend lxpattern
    }
    
    LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
    for (LXPattern pattern : lxPatterns) {
      pattern.setTransition(t);
    }
    
    channel = lx.engine.addChannel(lxPatterns);
    channel.setFaderTransition(new TreesTransition(lx, channel));
    getCurrentPattern().enableKeyboardPlayableMode();
  }
  
  KeyboardPlayablePattern getCurrentPattern() {
    return (KeyboardPlayablePattern) channel.getActivePattern();
  }
  
  public void noteOn(LXMidiNoteOn note) {
    if (channel != null) {
      getCurrentPattern().noteOn(note);
    }
  }
  
  public void noteOff(LXMidiNoteOff note) {
    if (channel != null) {
      getCurrentPattern().noteOff(note);
    }
  }
  
  public void modWheelChanged(float value) {
    if (channel != null) {
      getCurrentPattern().modWheelChanged(value);
    }
  }
}

interface KeyboardPlayablePattern {
  public void enableKeyboardPlayableMode();
  public void noteOn(LXMidiNoteOn note);
  public void noteOff(LXMidiNoteOff note);
  public void modWheelChanged(float value);
}


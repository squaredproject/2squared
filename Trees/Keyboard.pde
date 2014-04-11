class TSKeyboard implements Keyboard {
  
  KeyboardPlayablePattern[] patterns = null;
  LXDeck deck = null;
  
  boolean configure(MidiEngine midiEngine) {
    if (midiEngine.mpk25 == null) {
      return false;
    }
    
    patterns = new KeyboardPlayablePattern[] {
    };
    
    LXPattern[] lxPatterns = new LXPattern[patterns.length];
    for (int i = 0; i < patterns.length; i++) {
      lxPatterns[i] = (LXPattern)patterns[i]; // trust they extend lxpattern
    }
    
    LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
    for (LXPattern pattern : lxPatterns) {
      pattern.setTransition(t);
    }
    
    deck = lx.engine.addDeck(lxPatterns);
    deck.setFaderTransition(new TreesTransition(lx, deck));
    getCurrentPattern().enableKeyboardPlayableMode();
    
    midiEngine.mpk25.setKeyboard(this);
    
    return true;
  }
  
  KeyboardPlayablePattern getCurrentPattern() {
    return (KeyboardPlayablePattern)deck.getActivePattern();
  }
  
  public void noteOn(LXMidiNote note) {
    if (midiEngine.mpk25 != null && deck != null) {
      getCurrentPattern().noteOn(note);
    }
  }
  
  public void noteOff(LXMidiNote note) {
    if (midiEngine.mpk25 != null && deck != null) {
      getCurrentPattern().noteOff(note);
    }
  }
  
  public void modWheelChanged(int value) {
    if (midiEngine.mpk25 != null && deck != null) {
      getCurrentPattern().modWheelChanged(value);
    }
  }
}

interface KeyboardPlayablePattern {
  public void enableKeyboardPlayableMode();
  public void noteOn(LXMidiNote note);
  public void noteOff(LXMidiNote note);
  public void modWheelChanged(int value);
}


class TSKeyboard implements Keyboard {
  
  KeyboardPlayablePattern[] patterns = null;
  LXDeck deck = null;
  
  void configure(LX lx) {
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
  }
  
  KeyboardPlayablePattern getCurrentPattern() {
    return (KeyboardPlayablePattern)deck.getActivePattern();
  }
  
  public void noteOn(LXMidiNote note) {
    if (deck != null) {
      getCurrentPattern().noteOn(note);
    }
  }
  
  public void noteOff(LXMidiNote note) {
    if (deck != null) {
      getCurrentPattern().noteOff(note);
    }
  }
  
  public void modWheelChanged(int value) {
    if (deck != null) {
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


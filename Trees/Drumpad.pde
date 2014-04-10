import java.util.concurrent.ConcurrentLinkedQueue;

TriggerablePattern[] drumpadPatterns;
int drumpadDeckIndexStart;
int drumpadDeckIndexEnd;

TriggerablePattern[] drumpadPatterns(LX lx) {
  TriggerablePattern[] patterns = new TriggerablePattern[] {
    new Brightness(lx),
    new Explosions(lx),
    new Wisps(lx),
  };
  return patterns;
}

void setupDrumpad() {
  int drumpadDeckIndexStart = lx.engine.getDecks().size();
  
  drumpadPatterns = drumpadPatterns(lx);
  
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  for (TriggerablePattern pattern : drumpadPatterns) {
    pattern.setTransition(t);
    pattern.triggered.setValue(false);
    lx.engine.addDeck(new LXPattern[] { pattern });
  }
  
  int drumpadDeckIndexEnd = lx.engine.getDecks().size();
  
  for (int i = drumpadDeckIndexStart; i < drumpadDeckIndexEnd; i++) {
    LXDeck deck = lx.engine.getDeck(i);
    deck.getFader().setValue(1);
    deck.setFaderTransition(new TreesTransition(lx, deck));
  }
  
  if (midiEngine.mpk25 != null) {
    for (int i = 0; i < drumpadPatterns.length; i++) {
      midiEngine.mpk25.bindNote(drumpadPatterns[i].strength, MPK25_PAD_CHANNEL, MPK25_PAD_PITCHES[i]);
    }
  }
}

abstract class TriggerablePattern extends LXPattern {
  
  BasicParameter strength = new BasicParameter("strength");
  BooleanParameter triggered = new BooleanParameter("triggered", true);
  private final ConcurrentLinkedQueue<LXParameter> pendingParameterChanges = new ConcurrentLinkedQueue<LXParameter>();
  
  TriggerablePattern(LX lx) {
    super(lx);
    
    strength.addListener(new LXParameterListener() {
      void onParameterChanged(LXParameter parameter) {
        pendingParameterChanges.add(parameter);
      }
    });
  }
  
  public final void run(double deltaMs) {
    LXParameter parameterChange;
    while ((parameterChange = pendingParameterChanges.poll()) != null) {
      boolean isOn = parameterChange.getValue() != 0;
      if (triggered.getValueb() != isOn) {
        triggered.setValue(isOn);
        if (isOn) {
          onTriggerOn(parameterChange.getValuef());
        } else {
          onTriggerOff();
        }
      }
    }
    doRun(deltaMs);
  }
  
  public void onTriggerOn(float strength) { }
  public void onTriggerOff() { }
  
  abstract public void doRun(double deltaMs);
}


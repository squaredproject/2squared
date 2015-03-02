abstract class TSPattern extends LXPattern {

  protected final Model model;

  TSPattern(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }

  void onTriggerableModeEnabled() {
  }

  Triggerable getTriggerable() {
    return new ParameterTriggerableAdapter(getChannel().getFader());
  }
}

abstract class Effect extends LXEffect {

  protected final Model model;

  Effect(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }
}

abstract class Layer extends LXLayer {

  protected final Model model;

  Layer(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }
}

abstract class TSTriggerablePattern extends TSPattern implements Triggerable {

  static final int PATTERN_MODE_PATTERN = 0;
  static final int PATTERN_MODE_TRIGGER = 1; // calls the run loop only when triggered
  static final int PATTERN_MODE_FIRED = 2; // like triggered, but must disable itself when finished
  static final int PATTERN_MODE_CUSTOM = 3; // always calls the run loop

  int patternMode = PATTERN_MODE_TRIGGER;

  boolean triggerableModeEnabled;
  boolean triggered = true;
  double firedTimer = 0;

  TSTriggerablePattern(LX lx) {
    super(lx);
  }

  void onTriggerableModeEnabled() {
    getChannel().getFader().setValue(1);
    if (patternMode == PATTERN_MODE_TRIGGER || patternMode == PATTERN_MODE_FIRED) {
      getChannel().enabled.setValue(false);
    }
    triggerableModeEnabled = true;
    triggered = false;
  }

  Triggerable getTriggerable() {
    return this;
  }

  public void onTriggered(float strength) {
    if (patternMode == PATTERN_MODE_TRIGGER || patternMode == PATTERN_MODE_FIRED) {
      getChannel().enabled.setValue(true);
    }
    triggered = true;
    firedTimer = 0;
  }

  public void onRelease() {
    if (patternMode == PATTERN_MODE_TRIGGER) {
      getChannel().enabled.setValue(false);
    }
    triggered = false;
  }
}


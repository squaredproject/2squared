abstract class TSPattern extends LXPattern {
  TSPattern(LX lx) {
    super(lx);
  }

  void onTriggerableModeEnabled() {
    if (this instanceof Triggerable) {
      getChannel().getFader().setValue(1);
    }
  }

  Triggerable getTriggerable() {
    if (this instanceof Triggerable) {
      return (Triggerable)this;
    } else {
      return new ParameterTriggerableAdapter(getChannel().getFader());
    }
  }
}


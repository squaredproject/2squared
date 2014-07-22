class TSDrumpad implements Drumpad {
  
  Triggerable[] triggerables = null;
  
  private Triggerable[] triggerables(LX lx) {
    Triggerable[] triggerables = new Triggerable[] {
      new Brightness(lx),
      new Explosions(lx),
      new Wisps(lx),
      new Lightning(lx),
      new Pulley(lx),
    };
    return triggerables;
  }
  
  void configure(LX lx) {
    triggerables = triggerables(lx);
    
    LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
    for (Triggerable triggerable : triggerables) {
      LXPattern pattern = (LXPattern)triggerable; // trust they extend lxpattern
      pattern.setTransition(t);
      triggerable.enableTriggerableMode();
      LXChannel channel = lx.engine.addChannel(new LXPattern[] { pattern });
      channel.getFader().setValue(1);
      // channel.setFaderTransition(new TreesTransition(lx, channel));
    }
  }
  
  public void padTriggered(int index, int velocity) {
    if (triggerables != null && index < triggerables.length) {
      triggerables[index].onTriggered(velocity / 127.);
    }
  }
  
  public void padReleased(int index) {
    if (triggerables != null && index < triggerables.length) {
      triggerables[index].onRelease();
    }
  }
}

public interface Triggerable {
  public void enableTriggerableMode();
  public void onTriggered(float strength);
  public void onRelease();
}

public class ParameterTriggerableAdapter implements Triggerable {
  private final LXNormalizedParameter enabledParameter;
  private final double enabledValue;
  
  ParameterTriggerableAdapter(LXNormalizedParameter enabledParameter) {
    this(enabledParameter, 1);
  }
  
  ParameterTriggerableAdapter(LXNormalizedParameter enabledParameter, double enabledValue) {
    this.enabledParameter = enabledParameter;
    this.enabledValue = enabledValue;
  }
  
  public void enableTriggerableMode() {
  }
  
  public void onTriggered(float strength) {
    enabledParameter.setNormalized(enabledValue);
  }
  
  public void onRelease() {
    enabledParameter.setNormalized(0);
  }
}


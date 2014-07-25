class TSDrumpad implements Drumpad {
  
  Triggerable[][] triggerables = null;
  
  public void padTriggered(int row, int col, int velocity) {
    if (triggerables != null && row < triggerables.length && col < triggerables[row].length) {
      triggerables[row][col].onTriggered(velocity / 127.);
    }
  }
  
  public void padReleased(int row, int col) {
    if (triggerables != null && row < triggerables.length && col < triggerables[row].length) {
      triggerables[row][col].onRelease();
    }
  }
}

public interface Triggerable {
  public void enableTriggerableMode();
  public void onTriggered(float strength);
  public void onRelease();
}

public class ParameterTriggerableAdapter implements Triggerable, LXLoopTask {

  private final BasicParameter triggeredEventParameter = new BasicParameter("ANON");
  private final DampedParameter triggeredEventDampedParameter = new DampedParameter(triggeredEventParameter, 2);

  private final LXNormalizedParameter enabledParameter;
  private final double offValue;
  private final double onValue;
  
  ParameterTriggerableAdapter(LXNormalizedParameter enabledParameter) {
    this(enabledParameter, 0, 1);
  }
  
  ParameterTriggerableAdapter(LXNormalizedParameter enabledParameter, double offValue, double onValue) {
    this.enabledParameter = enabledParameter;
    this.offValue = offValue;
    this.onValue = onValue;

    lx.engine.addLoopTask(this);
    lx.engine.addModulator(triggeredEventDampedParameter.start());
  }

  void loop(double deltaMs) {
    enabledParameter.setNormalized(triggeredEventDampedParameter.getValue());
  }
  
  public void enableTriggerableMode() {
  }
  
  public void onTriggered(float strength) {
    triggeredEventParameter.setValue((onValue - offValue) * strength + offValue);
  }
  
  public void onRelease() {
    triggeredEventParameter.setValue(offValue);
  }
}


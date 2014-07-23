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

public class ParameterTriggerableAdapter implements Triggerable {
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
  }
  
  public void enableTriggerableMode() {
  }
  
  public void onTriggered(float strength) {
    enabledParameter.setNormalized(onValue);
  }
  
  public void onRelease() {
    enabledParameter.setNormalized(offValue);
  }
}


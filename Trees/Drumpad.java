import heronarts.lx.LX;
import heronarts.lx.LXLoopTask;
import heronarts.lx.modulator.DampedParameter;
import heronarts.lx.parameter.BasicParameter;
import heronarts.lx.parameter.LXNormalizedParameter;

interface Drumpad {
  public void padTriggered(int row, int col, float velocity);
  public void padReleased(int row, int col);
}

class TSDrumpad implements Drumpad {
  
  Triggerable[][] triggerables = null;
  
  public void padTriggered(int row, int col, float velocity) {
    if (triggerables != null && row < triggerables.length && col < triggerables[row].length) {
      triggerables[row][col].onTriggered(velocity);
    }
  }
  
  public void padReleased(int row, int col) {
    if (triggerables != null && row < triggerables.length && col < triggerables[row].length) {
      triggerables[row][col].onRelease();
    }
  }
}

interface Triggerable {
  public void onTriggered(float strength);
  public void onRelease();
}

class ParameterTriggerableAdapter implements Triggerable, LXLoopTask {

  private final LX lx;
  private final BasicParameter triggeredEventParameter = new BasicParameter("ANON");
  private final DampedParameter triggeredEventDampedParameter = new DampedParameter(triggeredEventParameter, 2);
  private boolean isDampening = false;
  private double strength;

  private final LXNormalizedParameter enabledParameter;
  private final double offValue;
  private final double onValue;
  
  ParameterTriggerableAdapter(LX lx, LXNormalizedParameter enabledParameter) {
    this(lx, enabledParameter, 0, 1);
  }
  
  ParameterTriggerableAdapter(LX lx, LXNormalizedParameter enabledParameter, double offValue, double onValue) {
    this.lx = lx;
    this.enabledParameter = enabledParameter;
    this.offValue = offValue;
    this.onValue = onValue;

    lx.engine.addLoopTask(this);
    lx.engine.addLoopTask(triggeredEventDampedParameter.start());
  }

  public void loop(double deltaMs) {
    if (isDampening) {
      enabledParameter.setValue((onValue - offValue) * strength * triggeredEventDampedParameter.getValue() + offValue);
      if (triggeredEventDampedParameter.getValue() == triggeredEventParameter.getValue()) {
        isDampening = false;
      }
    } else {
      if (triggeredEventDampedParameter.getValue() != triggeredEventParameter.getValue()) {
        enabledParameter.setValue((onValue - offValue) * strength * triggeredEventDampedParameter.getValue() + offValue);
        isDampening = true;
      }
    }
  }
  
  public void onTriggered(float strength) {
    this.strength = strength;
    triggeredEventDampedParameter.setValue((enabledParameter.getValue() - offValue) / (onValue - offValue));
    // println((enabledParameter.getValue() - offValue) / (onValue - offValue));
    triggeredEventParameter.setValue(1);
  }
  
  public void onRelease() {
    triggeredEventDampedParameter.setValue((enabledParameter.getValue() - offValue) / (onValue - offValue));
    triggeredEventParameter.setValue(0);
  }
}


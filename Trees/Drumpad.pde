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

public interface Triggerable {
  public void onTriggered(float strength);
  public void onRelease();
}

public class ParameterTriggerableAdapter implements Triggerable, LXLoopTask {

  private final BasicParameter triggeredEventParameter = new BasicParameter("ANON");
  private final DampedParameter triggeredEventDampedParameter = new DampedParameter(triggeredEventParameter, 2);
  private boolean isDampening = false;
  private double strength;

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
    speedIndependentContainer.addLoopTask(triggeredEventDampedParameter.start());
  }

  void loop(double deltaMs) {
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

// This is a place to add loop tasks that ignore the engine speed modifier
// This is helpful when you're adding something that isn't directly modifying
// the visuals. For example, a timer or modulator affecting UI controls.
class SpeedIndependentContainer implements LXLoopTask {

  private final List<LXLoopTask> loopTasks = new ArrayList<LXLoopTask>();

  private long nowMillis;
  private long lastMillis;

  SpeedIndependentContainer(LX lx) {
    lastMillis = System.currentTimeMillis();
  }

  public void addLoopTask(LXLoopTask loopTask) {
    this.loopTasks.add(loopTask);
  }

  public void loop(double deltaMsSkewed) {
    this.nowMillis = System.currentTimeMillis();
    double deltaMs = this.nowMillis - this.lastMillis;
    this.lastMillis = this.nowMillis;

    // Run loop tasks
    for (LXLoopTask loopTask : this.loopTasks) {
      loopTask.loop(deltaMs);
    }
  }
}


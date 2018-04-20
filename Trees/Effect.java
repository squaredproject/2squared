import heronarts.lx.LX;
import heronarts.lx.effect.LXEffect;
import heronarts.lx.model.LXModel;

abstract class Effect extends LXEffect {

  protected Model model;

  Effect(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }

  @Override
  public void loop(double deltaMs) {
    if (isEnabled()) {
      super.loop(deltaMs);
    }
  }

  @Override
  public void onModelChanged(LXModel model) {
    super.onModelChanged(model);
    this.model = (Model)model;
  }
}

class TSEffectController {

  String name;
  LXEffect effect;
  Triggerable triggerable;

  TSEffectController(String name, LXEffect effect, Triggerable triggerable) {
    this.name = name;
    this.effect = effect;
    this.triggerable = triggerable;
  }

  String getName() {
    return name;
  }

  boolean getEnabled() {
    return triggerable.isTriggered();
  }

  void setEnabled(boolean enabled) {
    if (enabled) {
      triggerable.onTriggered(1);
    } else {
      triggerable.onRelease();
    }
  }
}


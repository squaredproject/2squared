import java.util.List;

import heronarts.lx.LX;
import heronarts.lx.LXChannel;
import heronarts.lx.color.LXColor;
import heronarts.lx.effect.LXEffect;
import heronarts.lx.modulator.SinLFO;
import heronarts.lx.parameter.BooleanParameter;
import heronarts.lx.parameter.DiscreteParameter;
import heronarts.lx.parameter.LXParameter;
import heronarts.lx.parameter.LXParameterListener;
import heronarts.lx.modulator.QuadraticEnvelope;

class MappingTool extends Effect {

  final List<TreeConfig> clusterConfig;

  // final SinLFO strobe = new SinLFO(00, 20, 1000);
  final QuadraticEnvelope strobe = new QuadraticEnvelope(100, 0, 3000);
  
  final DiscreteParameter clusterIndex;
  final BooleanParameter showBlanks = new BooleanParameter("BLANKS", false);

  MappingTool(LX lx, List<TreeConfig> clusterConfig) {
    super(lx);
    this.clusterConfig = clusterConfig;
    clusterIndex = new DiscreteParameter("CLUSTER", clusterConfig.size());
    clusterIndex.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        strobe.setStartValue(100);
        strobe.trigger();
      }
    });
    addModulator(strobe).start();
    addLayer(new MappingLayer());
  }
  
  TreeConfig getConfig() {
    return clusterConfig.get(clusterIndex.getValuei());
  }
  
  Cluster getCluster() {
    return model.clustersByIp.get(getConfig().ipAddress);
  }

  void reloadModel() {
    lx.setModel(new Model(clusterConfig));
  }

  public void run(double deltaMs) {
  }
  
  class MappingLayer extends Layer {
    
    MappingLayer() {
      super(MappingTool.this.lx);
    }
    
    public void run(double deltaMs) {
      if (isEnabled()) {
        for (Cube cube : getCluster().cubes) {
          blendColor(cube.index, lx.hsb(0, 0, strobe.getValuef()), LXColor.Blend.ADD);
        }
      }
    }
  }
}

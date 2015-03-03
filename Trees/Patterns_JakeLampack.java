import heronarts.lx.LX;
import heronarts.lx.modulator.SawLFO;

class AcidTrip extends TSPattern {
  
  final SawLFO trails = new SawLFO(360, 0, 7000);
  
  AcidTrip(LX lx) {
    super(lx);

    addModulator(trails).start();
  }
    
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
   
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        Math.abs(model.cy - cube.transformedY) + Math.abs(model.cy - cube.transformedTheta) + trails.getValuef() % 360,
        100,
        100
      );
    }
  }
}


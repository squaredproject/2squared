class SparkleHelix extends LXPattern {
  final BasicParameter minCoil = new BasicParameter("MinCOIL", .02, .005, .05);
  final BasicParameter maxCoil = new BasicParameter("MaxCOIL", .03, .005, .05);
  final BasicParameter sparkle = new BasicParameter("Spark", 80, 160, 10);
  final BasicParameter sparkleSaturation = new BasicParameter("Sat", 50, 0, 100);
  final BasicParameter counterSpiralStrength = new BasicParameter("Double", 0, 0, 1);
  
  final SinLFO coil = new SinLFO(minCoil, maxCoil, 8000);
  final SinLFO rate = new SinLFO(6000, 1000, 19000);
  final SawLFO spin = new SawLFO(0, TWO_PI, rate);
  final SinLFO width = new SinLFO(10, 20, 11000);
  int[] sparkleTimeOuts;
  SparkleHelix(LX lx) {
    super(lx);
    addParameter(minCoil);
    addParameter(maxCoil);
    addParameter(sparkle);
    addParameter(sparkleSaturation);
    addParameter(counterSpiralStrength);
    

    addModulator(rate.start());
    addModulator(coil.start());    
    addModulator(spin.start());
    addModulator(width.start());
    sparkleTimeOuts = new int[model.cubes.size()];
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      float compensatedWidth = (0.7 + .02 / coil.getValuef()) * width.getValuef();
      float spiralVal = max(0, 100 - (100*TWO_PI / (compensatedWidth))*LXUtils.wrapdistf(cube.theta, 8*TWO_PI + spin.getValuef() + coil.getValuef()*(cube.y-model.cy), TWO_PI));
      float counterSpiralVal = counterSpiralStrength.getValuef() * max(0, 100 - (100*TWO_PI / (compensatedWidth))*LXUtils.wrapdistf(cube.theta, 8*TWO_PI - spin.getValuef() - coil.getValuef()*(cube.y-model.cy), TWO_PI));
      float hueVal = (lx.getBaseHuef() + .1*cube.y) % 360;
      if (sparkleTimeOuts[cube.index] > millis()){        
        colors[cube.index] = lx.hsb(hueVal, sparkleSaturation.getValuef(), 100);
      }
      else{
        colors[cube.index] = lx.hsb(hueVal, 100, max(spiralVal, counterSpiralVal));        
        if (random(max(spiralVal, counterSpiralVal)) > sparkle.getValuef()){
          sparkleTimeOuts[cube.index] = millis() + 100;
        }
      }
    }
  }
}


class Stripes extends LXPattern {
  final BasicParameter minSpacing = new BasicParameter("MinSpacing", 0.5, .3, 2.5);
  final BasicParameter maxSpacing = new BasicParameter("MaxSpacing", 2, .3, 2.5);
  final SinLFO spacing = new SinLFO(minSpacing, maxSpacing, 8000);
  final SinLFO slopeFactor = new SinLFO(0.05, 0.2, 19000);

  int[] sparkleTimeOuts;
  Stripes(LX lx) {
    super(lx);
    addParameter(minSpacing);
    addParameter(maxSpacing);
    addModulator(slopeFactor.start());
    addModulator(spacing.start());    
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {  
      float hueVal = (lx.getBaseHuef() + .1*cube.y) % 360;
      float brightVal = (50 + 50 * sin(spacing.getValuef() * (sin(4 * cube.theta) + slopeFactor.getValuef() * cube.y))) % 100; 
      colors[cube.index] = lx.hsb(hueVal,  100, brightVal);
    }
  }
}


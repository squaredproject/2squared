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
      float spiralVal = max(0, 100 - (100*TWO_PI / (compensatedWidth))*LXUtils.wrapdistf((TWO_PI / 360) * cube.theta, 8*TWO_PI + spin.getValuef() + coil.getValuef()*(cube.y-model.cy), TWO_PI));
      float counterSpiralVal = counterSpiralStrength.getValuef() * max(0, 100 - (100*TWO_PI / (compensatedWidth))*LXUtils.wrapdistf((TWO_PI / 360) * cube.theta, 8*TWO_PI - spin.getValuef() - coil.getValuef()*(cube.y-model.cy), TWO_PI));
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
      float brightVal = (50 + 50 * sin(spacing.getValuef() * (sin((TWO_PI / 360) * 4 * cube.theta) + slopeFactor.getValuef() * cube.y))) % 100; 
      colors[cube.index] = lx.hsb(hueVal,  100, brightVal);
    }
  }
}




class SparkleTakeOver extends LXPattern {


  int[] sparkleTimeOuts;
  int[] cubeStates;
  int lastComplimentaryToggle = 0;
  int complimentaryToggle = 0;
  boolean resetDone = false;
  final SinLFO timing = new SinLFO(6000, 10000, 20000);
  final SawLFO coverage = new SawLFO(0, 100, timing);
  final BasicParameter hueVariation = new BasicParameter("HueVar", 0.1, 0.1, 0.4);
  float hueSeparation = 180;
  int resetTimeOut = 0;
  float newHueVal;
  float oldHueVal;
  float newBrightVal = 100;
  float oldBrightVal = 100;
  SparkleTakeOver(LX lx) {
    super(lx);
    sparkleTimeOuts = new int[model.cubes.size()];
    addModulator(timing.start());    
    addModulator(coverage.start());
    addParameter(hueVariation);
  }  
  public void run(double deltaMs) {
    if (coverage.getValuef() < 6){
      if (resetDone == false){
        lastComplimentaryToggle = complimentaryToggle;
        oldBrightVal = newBrightVal;
        if (random(5) < 2){          
          complimentaryToggle = 1 - complimentaryToggle;
          newBrightVal = 100;
        }
        else {
          newBrightVal = (newBrightVal == 100) ? 70 : 100;          
        }
        for (int i = 0; i < model.cubes.size(); i++){
          sparkleTimeOuts[i] = 0;
        }        
        resetDone = true;
      }
    }     
    else {
      resetDone = false;
    }
    for (Cube cube : model.cubes) {  
      float newHueVal = (lx.getBaseHuef() + complimentaryToggle * hueSeparation + hueVariation.getValuef() * cube.y) % 360;
      float oldHueVal = (lx.getBaseHuef() + lastComplimentaryToggle * hueSeparation + hueVariation.getValuef() * cube.y) % 360;
      if (sparkleTimeOuts[cube.index] > millis()){        
        colors[cube.index] = lx.hsb(newHueVal,  (30 + coverage.getValuef()) / 1.3, newBrightVal);
      }
      else {
        colors[cube.index] = lx.hsb(oldHueVal,  (140 - coverage.getValuef()) / 1.4, oldBrightVal);
        float chance = random(abs(sin((TWO_PI / 360) * cube.theta * 4) * 50) + abs(sin(TWO_PI * (cube.y / 1000))) * 50);
        if (chance > (100 - 100*(pow(coverage.getValuef()/100, 2)))){
          sparkleTimeOuts[cube.index] = millis() + 50000;
        }
        else if (chance > 1.1 * (100 - coverage.getValuef())){
          sparkleTimeOuts[cube.index] = millis() + 100;
        }
          
      }
        
    }
  }
}
class Twinkle extends LXPattern {

  private SinLFO[] bright;
  final BasicParameter speedParam = new BasicParameter("Speed", 0.5, 0, 10);
  final BasicParameter brightnessParam = new BasicParameter("Brightness", 0.8, 0.5, 1);
  final int numBrights = 18;
  final int density = 20;
  int[] sparkleTimeOuts;
  int[] cubeToModulatorMapping;

  Twinkle(LX lx) {
    super(lx);
    addParameter(speedParam);
    addParameter(brightnessParam);

    sparkleTimeOuts = new int[model.cubes.size()];
    cubeToModulatorMapping = new int[model.cubes.size()];

    for (int i = 0; i < cubeToModulatorMapping.length; i++ ) {
      cubeToModulatorMapping[i] = int(random(numBrights));
    }    

    bright = new SinLFO[numBrights];
    int numLight = density / 100 * bright.length; // number of brights array that are most bright
    int numDarkReverse = (bright.length - numLight) / 2; // number of brights array that go from light to dark

    for (int i = 0; i < bright.length; i++ ) {
      if (i <= numLight) {
        if (random(1) < 0.5) {
          bright[i] = new SinLFO(int(random(80, 100)), 0, int(random(11300, 17700)));
        } 
        else {
          bright[i] = new SinLFO(0, int(random(80, 100)), int(random(9300, 14200)));
        }
      } 
      else if ( i < numDarkReverse ) {
        bright[i] = new SinLFO(int(random(60, 70)), 0, int(random(7300, 25300)));
      } 
      else {
        bright[i] = new SinLFO(0, int(random(50, 80)), int(random(9300, 23300)));
      }
      addModulator(bright[i].start());
    }
  }

  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      if (sparkleTimeOuts[cube.index] < millis()) {
        // randomly change modulators        
        if (random(10) <= speedParam.getValuef()) {
          cubeToModulatorMapping[cube.index] = int(random(numBrights));
        }
        sparkleTimeOuts[cube.index] = millis() + int(random(17100, 33300));
      }
      colors[cube.index] = lx.hsb(
      0, 
      0, 
      bright[cubeToModulatorMapping[cube.index]].getValuef() * brightnessParam.getValuef()
        );
    }
  }
}

class VerticalSweep extends LXPattern {

  final BasicParameter saturationParam = new BasicParameter("Saturation", 100, 0, 100);
  final BasicParameter hue1Param = new BasicParameter("Hue1", 60, 0, 360);
  final BasicParameter hue2Param = new BasicParameter("Hue2", 110, 0, 360);
  final BasicParameter hue3Param = new BasicParameter("Hue3", 180, 0, 360);

  final SawLFO range = new SawLFO(0, 1, 5000);

  VerticalSweep(LX lx) {
    super(lx);
    addModulator(range.start());
    addParameter(saturationParam);
    addParameter(hue1Param);
    addParameter(hue2Param);
    addParameter(hue3Param);
  }

  public void run(double deltaMs) {

    float[] colorPalette = { 
      hue1Param.getValuef(), hue2Param.getValuef(), hue3Param.getValuef()
      };
      int saturation = (int) saturationParam.getValuef();

    for (Cube cube : model.cubes) {
      float progress = ((cube.theta / 360.0) + range.getValuef()) % 1; // value is 0-1
      float scaledProgress = (colorPalette.length) * progress; // value is 0-3
      int color1Index = floor(scaledProgress);
      int color1Hue = (int) colorPalette[color1Index];
      int color2Hue = (int) colorPalette[ceil(scaledProgress) % colorPalette.length];
      color color1 = lx.hsb( color1Hue, saturation, 100 );
      color color2 = lx.hsb( color2Hue, saturation, 100 );
      float amt = scaledProgress-color1Index;

      colors[cube.index] = lerpColor(color1, color2, amt);
    }
  }
}


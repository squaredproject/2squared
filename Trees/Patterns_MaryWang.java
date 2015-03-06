import heronarts.lx.LX;
import heronarts.lx.color.LXColor;
import heronarts.lx.modulator.SawLFO;
import heronarts.lx.modulator.SinLFO;
import heronarts.lx.parameter.BasicParameter;

import toxi.math.MathUtils;

class Twinkle extends TSPattern {

  private SinLFO[] bright;
  final BasicParameter brightnessParam = new BasicParameter("Brightness", 0.8, 0.5, 1);
  final int numBrights = 18;
  final int density = 20;
  int[] sparkleTimeOuts;
  int[] cubeToModulatorMapping;

  Twinkle(LX lx) {
    super(lx);
    addParameter(brightnessParam);

    sparkleTimeOuts = new int[model.cubes.size()];
    cubeToModulatorMapping = new int[model.cubes.size()];

    for (int i = 0; i < cubeToModulatorMapping.length; i++ ) {
      cubeToModulatorMapping[i] = MathUtils.random(numBrights);
    }    

    bright = new SinLFO[numBrights];
    int numLight = density / 100 * bright.length; // number of brights array that are most bright
    int numDarkReverse = (bright.length - numLight) / 2; // number of brights array that go from light to dark

    for (int i = 0; i < bright.length; i++ ) {
      if (i <= numLight) {
        if (MathUtils.random(1f) < 0.5) {
          bright[i] = new SinLFO(MathUtils.random(80f, 100f), 0, MathUtils.random(2300f, 7700f));
        } 
        else {
          bright[i] = new SinLFO(0, MathUtils.random(70f, 90f), MathUtils.random(5300f, 9200f));
        }
      } 
      else if ( i < numDarkReverse ) {
        bright[i] = new SinLFO(MathUtils.random(50f, 70f), 0, MathUtils.random(3300f, 11300f));
      } 
      else {
        bright[i] = new SinLFO(0, MathUtils.random(30f, 80f), MathUtils.random(3100f, 9300f));
      }
      addModulator(bright[i]).start();
    }
  }

  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      if (sparkleTimeOuts[cube.index] < Utils.millis()) {
        // randomly change modulators        
        if (MathUtils.random(10f) <= 3) {
          cubeToModulatorMapping[cube.index] = MathUtils.random(numBrights);
        }
        sparkleTimeOuts[cube.index] = Utils.millis() + MathUtils.random(11100, 23300);
      }
      colors[cube.index] = lx.hsb(
      0, 
      0, 
      bright[cubeToModulatorMapping[cube.index]].getValuef() * brightnessParam.getValuef()
        );
    }
  }
}

class VerticalSweep extends TSPattern {

  final BasicParameter saturationParam = new BasicParameter("Saturation", 100, 0, 100);
  final BasicParameter hue1Param = new BasicParameter("Hue1", 60, 0, 360);
  final BasicParameter hue2Param = new BasicParameter("Hue2", 110, 0, 360);
  final BasicParameter hue3Param = new BasicParameter("Hue3", 180, 0, 360);

  final SawLFO range = new SawLFO(0, 1, 5000);

  VerticalSweep(LX lx) {
    super(lx);
    addModulator(range).start();
    addParameter(saturationParam);
    addParameter(hue1Param);
    addParameter(hue2Param);
    addParameter(hue3Param);
  }

  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    float[] colorPalette = { 
      hue1Param.getValuef(), hue2Param.getValuef(), hue3Param.getValuef()
      };
      int saturation = (int) saturationParam.getValuef();

    for (Cube cube : model.cubes) {
      float progress = ((cube.transformedTheta / 360.0f) + range.getValuef()) % 1; // value is 0-1
      float scaledProgress = (colorPalette.length) * progress; // value is 0-3
      int color1Index = MathUtils.floor(scaledProgress);
      int color1Hue = (int) colorPalette[color1Index];
      int color2Hue = (int) colorPalette[(int)Math.ceil(scaledProgress) % colorPalette.length];
      int color1 = lx.hsb( color1Hue, saturation, 100 );
      int color2 = lx.hsb( color2Hue, saturation, 100 );
      float amt = scaledProgress-color1Index;

      colors[cube.index] = LXColor.lerp(color1, color2, amt);
    }
  }
}

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
        sparkleTimeOuts[cube.index] = millis() + int(random(17100,33300));
      }
      colors[cube.index] = lx.hsb(
        0, 
        0, 
        bright[cubeToModulatorMapping[cube.index]].getValuef() * brightnessParam.getValuef()
        );
    }
  }
}


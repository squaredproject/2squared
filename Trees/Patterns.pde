class DiffusionTestPattern extends LXPattern {
  
  final BasicParameter hue = new BasicParameter("HUE", 0, 360);
  final BasicParameter sat = new BasicParameter("SAT", 1);
  final BasicParameter brt = new BasicParameter("BRT", 1);
  
  DiffusionTestPattern(LX lx) {
    super(lx);
    addParameter(hue);
    addParameter(sat);
    addParameter(brt);
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
    for (int i = 6; i < 12; ++i) {
      colors[i] = color(
        hue.getValuef() % 360,
        sat.getValuef() * 100,
        brt.getValuef() * 100
      );
    }
  }
}

class TestPattern extends LXPattern {
  
  int CUBE_MOD = 14;
  
  final BasicParameter period = new BasicParameter("RATE", 3000, 6000);
  final SinLFO cubeIndex = new SinLFO(0, CUBE_MOD, period);
  
  TestPattern(LX lx) {
    super(lx);
    addModulator(cubeIndex.start());
    addParameter(period);
  }
  
  public void run(double deltaMs) {
    int ci = 0;
    for (Cube cube : model.cubes) {
      setColor(cube, color(
        (lx.getBaseHuef() + cube.cx + cube.cy) % 360,
        100,
        max(0, 100 - 30*abs((ci % CUBE_MOD) - cubeIndex.getValuef()))
      ));
      ++ci;
    }
  }
}


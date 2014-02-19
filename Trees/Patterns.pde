class SweepPattern extends LXPattern {
  
  final SinLFO speedMod = new SinLFO(1000, 5000, 1800);
  final SinLFO yPos = new SinLFO(model.yMin, model.yMax, speedMod);
  final BasicParameter width = new BasicParameter("WIDTH", 10, 5, 100);
  
  SweepPattern(LX lx) {
    super(lx);
    addModulator(speedMod.start());
    addModulator(yPos.start());
    addParameter(width);
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      setColor(cube, color(
        (lx.getBaseHuef() + 2*cube.cz) % 360,
        100,
        max(0, 100 - (100/width.getValuef())*abs(cube.cy - yPos.getValuef()))
      ));
    }
  }
}

class DiffusionTestPattern extends LXPattern {
  
  final BasicParameter hue = new BasicParameter("HUE", 0, 360);
  final BasicParameter sat = new BasicParameter("SAT", 1);
  final BasicParameter brt = new BasicParameter("BRT", 1);
  final BasicParameter spread = new BasicParameter("SPREAD", 0, 360);
  
  DiffusionTestPattern(LX lx) {
    super(lx);
    addParameter(hue);
    addParameter(sat);
    addParameter(brt);
    addParameter(spread);
  }
  
  public void run(double deltaMs) {
    setColors(#000000);
    for (int i = 0; i < 12; ++i) {
      colors[i] = color(
        (hue.getValuef() + (i / 4) * spread.getValuef()) % 360,
        sat.getValuef() * 100,
        min(100, brt.getValuef() * (i+1) / 12. * 200)
      );
    }
  }
}

class TestPattern extends LXPattern {
  
  int CUBE_MOD = 14;
  
  final BasicParameter period = new BasicParameter("RATE", 3000, 2000, 6000);
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


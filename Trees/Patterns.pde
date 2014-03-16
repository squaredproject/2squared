class TestCluster extends LXPattern {
  final DiscreteParameter lightNo = new DiscreteParameter("LIGHT", 0, 16);
  
  TestCluster(LX lx) {
    super(lx);
    addParameter(lightNo);
  }
  
  public void run(double deltaMs) {
    int ci = 0;
    for (Cluster cluster : model.clusters) {
        for (Cube cube : cluster.cubes) {
          if (ci == lightNo.getValuei()) {
            setColor(cube, lx.hsb(
              cube.index * 15,
              100,
              100
            )); 
        } else {
          setColor(cube, 0);
        }
      ++ci;
      }
      ci = 0;
    }
  }
}

class SweepPattern extends LXPattern {
  
  final SinLFO speedMod = new SinLFO(3000, 9000, 5400);
  final SinLFO yPos = new SinLFO(model.yMin, model.yMax, speedMod);
  final BasicParameter width = new BasicParameter("WIDTH", 50, 5, 100);
  
  final SawLFO offset = new SawLFO(0, TWO_PI, 9000);
  
  final BasicParameter amplitude = new BasicParameter("AMP", 10*FEET, 0, 20*FEET);
  final SinLFO amp = new SinLFO(0, amplitude, 5000);
  
  SweepPattern(LX lx) {
    super(lx);
    addModulator(speedMod.start());
    addModulator(yPos.start());
    addParameter(width);
    addParameter(amplitude);
    addModulator(amp.start());
    addModulator(offset.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      float yp = yPos.getValuef() + amp.getValuef() * sin((cube.cx - model.cx) * .01 + offset.getValuef());
      setColor(cube, lx.hsb(
        (lx.getBaseHuef() + abs(cube.cx - model.cx) * .2 +  cube.cz*.1 + cube.cy*.1) % 360,
        100,
        max(0, 100 - (100/width.getValuef())*abs(cube.cy - yp))
      ));
    }
  }
}

class Twister extends LXPattern {

  final SinLFO spin = new SinLFO(0, 5*360, 16000);
  
  float coil(float basis) {
    return sin(basis*TWO_PI - PI);
  }
  
  Twister(LX lx) {
    super(lx);
    addModulator(spin.start());
  }
  
  public void run(double deltaMs) {
    float spinf = spin.getValuef();
    float coilf = 2*coil(spin.getBasisf());
    for (Cube cube : model.cubes) {
      float wrapdist = LXUtils.wrapdistf(cube.theta, spinf + (model.yMax - cube.y)*coilf, 360);
      float yn = (cube.y / model.yMax);
      float width = 10 + 30 * yn;
      float df = max(0, 100 - (100 / 45) * max(0, wrapdist-width));
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + .2*cube.y - 360 - wrapdist) % 360,
        max(0, 100 - 500*max(0, yn-.8)),
        df
      );
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
      colors[i] = lx.hsb(
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
      setColor(cube, lx.hsb(
        (lx.getBaseHuef() + cube.cx + cube.cy) % 360,
        100,
        max(0, 100 - 30*abs((ci % CUBE_MOD) - cubeIndex.getValuef()))
      ));
      ++ci;
    
    }
  }
}

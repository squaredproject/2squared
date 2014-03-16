class DoubleHelix extends LXPattern {
  
  final SinLFO rate = new SinLFO(400, 3000, 11000);
  final SawLFO theta = new SawLFO(0, 180, rate);
  final SinLFO coil = new SinLFO(0.2, 2, 13000);
  
  DoubleHelix(LX lx) {
    super(lx);
    addModulator(rate.start());
    addModulator(theta.start());
    addModulator(coil.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      float coilf = coil.getValuef() * (cube.cy - model.cy);
      colors[cube.index] = lx.hsb(
        lx.getBaseHuef() + .4*abs(cube.y - model.cy) +.2* abs(cube.theta - 180),
        100,
        max(0, 100 - 3*LXUtils.wrapdistf(cube.theta, theta.getValuef() + coilf, 180))
      );
    }
  }
}

class ColoredLeaves extends LXPattern {
  
  private SawLFO[] movement;
  private SinLFO[] bright;
  
  ColoredLeaves(LX lx) {
    super(lx);
    movement = new SawLFO[3];
    for (int i = 0; i < movement.length; ++i) {
      movement[i] = new SawLFO(0, 360, 60000 / (1 + i));
      addModulator(movement[i].start());
    }
    bright = new SinLFO[5];
    for (int i = 0; i < bright.length; ++i) {
      bright[i] = new SinLFO(100, 0, 60000 / (1 + i));
      addModulator(bright[i].start());
    }
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        (360 + movement[cube.index  % movement.length].getValuef()) % 360,
        100,
        bright[cube.index % bright.length].getValuef()
      );
    }
  }
}

class SeeSaw extends LXPattern {
  
  final LXProjection projection = new LXProjection(model);

  final SinLFO rate = new SinLFO(2000, 11000, 19000);
  final SinLFO rz = new SinLFO(-15, 15, rate);
  final SinLFO rx = new SinLFO(-70, 70, 11000);
  final SinLFO width = new SinLFO(1*FEET, 8*FEET, 13000);
  
  SeeSaw(LX lx) {
    super(lx);
    addModulator(rate.start());
    addModulator(rx.start());
    addModulator(rz.start());
    addModulator(width.start());
  }
  
  public void run(double deltaMs) {
    projection
      .reset()
      .center()
      .rotate(rx.getValuef() * PI / 180, 1, 0, 0)
      .rotate(rz.getValuef() * PI / 180, 0, 0, 1);
    for (LXVector v : projection) {
      colors[v.index] = lx.hsb(
        (lx.getBaseHuef() + min(120, abs(v.y))) % 360,
        100,
        max(bgLevel.getValuef(), 100 - (100/(1*FEET))*max(0, abs(v.y) - 0.5*width.getValuef()))
      );
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

class SweepPattern extends LXPattern {
  
  final SinLFO speedMod = new SinLFO(3000, 9000, 5400);
  final SinLFO yPos = new SinLFO(model.yMin, model.yMax, speedMod);
  final SinLFO width = new SinLFO("WIDTH", 2*FEET, 20*FEET, 19000);
  
  final SawLFO offset = new SawLFO(0, TWO_PI, 9000);
  
  final BasicParameter amplitude = new BasicParameter("AMP", 10*FEET, 0, 20*FEET);
  final SinLFO amp = new SinLFO(0, amplitude, 5000);
  
  SweepPattern(LX lx) {
    super(lx);
    addModulator(speedMod.start());
    addModulator(yPos.start());
    addModulator(width.start());
    addParameter(amplitude);
    addModulator(amp.start());
    addModulator(offset.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      float yp = yPos.getValuef() + amp.getValuef() * sin((cube.cx - model.cx) * .01 + offset.getValuef());
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + abs(cube.x - model.cx) * .2 +  cube.cz*.1 + cube.cy*.1) % 360,
        constrain(abs(cube.y - model.cy), 0, 100),
        max(0, 100 - (100/width.getValuef())*abs(cube.cy - yp))
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


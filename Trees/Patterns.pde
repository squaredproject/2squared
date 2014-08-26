class DoubleHelix extends TSPattern {
  
  final SinLFO rate = new SinLFO(400, 3000, 11000);
  final SawLFO theta = new SawLFO(0, 180, rate);
  final SinLFO coil = new SinLFO(0.2, 2, 13000);
  
  DoubleHelix(LX lx) {
    super(lx);
    addModulator(rate).start();
    addModulator(theta).start();
    addModulator(coil).start();
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      float coilf = coil.getValuef() * (cube.cy - model.cy);
      colors[cube.index] = lx.hsb(
        lx.getBaseHuef() + .4*abs(cube.transformedY - model.cy) +.2* abs(cube.transformedTheta - 180),
        100,
        max(0, 100 - 2*LXUtils.wrapdistf(cube.transformedTheta, theta.getValuef() + coilf, 180))
      );
    }
  }
}

class ColoredLeaves extends TSPattern {
  
  private SawLFO[] movement;
  private SinLFO[] bright;
  
  ColoredLeaves(LX lx) {
    super(lx);
    movement = new SawLFO[3];
    for (int i = 0; i < movement.length; ++i) {
      movement[i] = new SawLFO(0, 360, 60000 / (1 + i));
      addModulator(movement[i]).start();
    }
    bright = new SinLFO[5];
    for (int i = 0; i < bright.length; ++i) {
      bright[i] = new SinLFO(100, 0, 60000 / (1 + i));
      addModulator(bright[i]).start();
    }
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        (360 + movement[cube.index  % movement.length].getValuef()) % 360,
        100,
        bright[cube.index % bright.length].getValuef()
      );
    }
  }
}

class SeeSaw extends TSPattern {
  
  final LXProjection projection = new LXProjection(model);

  final SinLFO rate = new SinLFO(2000, 11000, 19000);
  final SinLFO rz = new SinLFO(-15, 15, rate);
  final SinLFO rx = new SinLFO(-70, 70, 11000);
  final SinLFO width = new SinLFO(1*FEET, 8*FEET, 13000);
  
  SeeSaw(LX lx) {
    super(lx);
    addModulator(rate).start();
    addModulator(rx).start();
    addModulator(rz).start();
    addModulator(width).start();
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

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

class Twister extends TSPattern {

  final SinLFO spin = new SinLFO(0, 5*360, 16000);
  
  float coil(float basis) {
    return sin(basis*TWO_PI - PI);
  }
  
  Twister(LX lx) {
    super(lx);
    addModulator(spin).start();
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    float spinf = spin.getValuef();
    float coilf = 2*coil(spin.getBasisf());
    for (Cube cube : model.cubes) {
      float wrapdist = LXUtils.wrapdistf(cube.transformedTheta, spinf + (model.yMax - cube.transformedY)*coilf, 360);
      float yn = (cube.transformedY / model.yMax);
      float width = 10 + 30 * yn;
      float df = max(0, 100 - (100 / 45) * max(0, wrapdist-width));
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + .2*cube.transformedY - 360 - wrapdist) % 360,
        max(0, 100 - 500*max(0, yn-.8)),
        df
      );
    }
  }
}

class SweepPattern extends TSPattern {
  
  final SinLFO speedMod = new SinLFO(3000, 9000, 5400);
  final SinLFO yPos = new SinLFO(model.yMin, model.yMax, speedMod);
  final SinLFO width = new SinLFO("WIDTH", 2*FEET, 20*FEET, 19000);
  
  final SawLFO offset = new SawLFO(0, TWO_PI, 9000);
  
  final BasicParameter amplitude = new BasicParameter("AMP", 10*FEET, 0, 20*FEET);
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0, 3);
  final BasicParameter height = new BasicParameter("HEIGHT", 0, -300, 300);
  final SinLFO amp = new SinLFO(0, amplitude, 5000);
  
  SweepPattern(LX lx) {
    super(lx);
    addModulator(speedMod).start();
    addModulator(yPos).start();
    addModulator(width).start();
    addParameter(amplitude);
    addParameter(speed);
    addParameter(height);
    addModulator(amp).start();
    addModulator(offset).start();
  }
  
  void onParameterChanged(LXParameter parameter) {
    super.onParameterChanged(parameter);
    if (parameter == speed) {
      float speedVar = 1/speed.getValuef();
      speedMod.setRange(9000 * speedVar,5400 * speedVar);
    }
  }
  
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      float yp = yPos.getValuef() + amp.getValuef() * sin((cube.cx - model.cx) * .01 + offset.getValuef());
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + abs(cube.x - model.cx) * .2 +  cube.cz*.1 + cube.cy*.1) % 360,
        constrain(abs(cube.transformedY - model.cy), 0, 100),
        max(0, 100 - (100/width.getValuef())*abs(cube.cy - yp - height.getValuef()))
      );
    }
  }
}

class DiffusionTestPattern extends TSPattern {
  
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
    if (getChannel().getFader().getNormalized() == 0) return;

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

class TestPattern extends TSPattern {
  
  int CUBE_MOD = 14;
  
  final BasicParameter period = new BasicParameter("RATE", 3000, 2000, 6000);
  final SinLFO cubeIndex = new SinLFO(0, CUBE_MOD, period);
  
  TestPattern(LX lx) {
    super(lx);
    addModulator(cubeIndex).start();
    addParameter(period);
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

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

class TestCluster extends TSPattern {
  final DiscreteParameter lightNo = new DiscreteParameter("LIGHT", 0, 19);
  final BasicParameter pos = new BasicParameter("POS", 0); 
  
  TestCluster(LX lx) {
    super(lx);
    addParameter(lightNo);
    addParameter(pos);
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cluster cluster : model.clusters) {
      for (Cube cube : cluster.cubes) {
        if (lightNo.getValuei() >= 17) {
          float d = (lightNo.getValuei() == 17) ?
            ((cube.transformedY - cluster.yMin) / cluster.yRange) :
            ((cube.x - cluster.xMin) / cluster.xRange); 
          setColor(cube, lx.hsb(
            lx.getBaseHuef(),
            100,
            max(0, 100 - 400*abs(d - pos.getValuef()))
          ));
        } else if ((cube.clusterPosition == lightNo.getValuei()) ||
            (0 == lightNo.getValuei())) {
          setColor(cube, lx.hsb(
            lx.getBaseHuef(),
            100,
            100
          )); 
        } else {
          setColor(cube, 0);
        }
      }
    }
  }
}

class ColorEffect extends LXEffect {
  
  final BasicParameter desaturation = new BasicParameter("WHT", 0);
  final BasicParameter hueShift = new BasicParameter("HUE", 0, 360);
  final BasicParameter sharp = new BasicParameter("SHRP", 0);
  final BasicParameter soft = new BasicParameter("SOFT", 0);
  final BasicParameter mono = new BasicParameter("MON", 0);
  final BasicParameter rainbow = new BasicParameter("ACID", 0);
  
  private final DampedParameter hueShiftd = new DampedParameter(hueShift, 180);
  private final DampedParameter rainbowd = new DampedParameter(rainbow, 1);
  
  private float[] hsb = new float[3];
  
  ColorEffect(LX lx) {
    super(lx);
    addParameter(desaturation);
    addParameter(hueShift);
    addParameter(sharp);
    addParameter(soft);
    addParameter(mono);
    addParameter(rainbow);
    
    addModulator(hueShiftd).start();
    addModulator(rainbowd).start();
  }
  
  protected void run(double deltaMs) {
    float desatf = desaturation.getValuef();
    float huef = hueShiftd.getValuef();
    float sharpf = sharp.getValuef();
    float softf = soft.getValuef();
    float monof = mono.getValuef();
    float rainbowf = rainbowd.getValuef();
    if (desatf > 0 || huef > 0 || sharpf > 0 || softf > 0 || monof > 0 || rainbowf > 0) {
      float pSharp = 1/(1-.99*sharpf);
      for (int i = 0; i < colors.length; ++i) {
        float b = LXColor.b(colors[i]) / 100.;
        float bOrig = b;
        if (sharpf > 0) {
          if (b < .5) {
            b = pow(b, pSharp);
          } else {
            b = 1-pow(1-b, pSharp);
          }
        }
        if (softf > 0) {
          if (b > 0.5) {
            b = lerp(b, 0.5 + 2 * (b-0.5)*(b-0.5), softf);
          } else {
            b = lerp(b, 0.5 * sqrt(2*b), softf);
          }
        }
        
        float h = LXColor.h(colors[i]);
        float bh = lx.getBaseHuef();
        if (rainbowf > 0) {
          h = bh + (h - bh) * (1+3*rainbowf);
          h = (h + 5*360) % 360;
        }
        if (abs(h - bh) > 180) {
          if (h > bh) {
            bh += 360;
          } else {
            h += 360;
          }
        }
        
        colors[i] = lx.hsb(
          (lerp(h, bh, monof) + huef) % 360,
          LXColor.s(colors[i]) * (1 - desatf),
          100*b
        );
      }
    }
  }
}


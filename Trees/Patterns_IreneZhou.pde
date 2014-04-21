class Lattice extends LXPattern {
  final SawLFO spin = new SawLFO(0, 4320, 24000); 
  final SinLFO yClimb = new SinLFO(60, 30, 24000);
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  final BasicParameter yHeight = new BasicParameter("HEIGHT", 0, -500, 500);

  float coil(float basis) {
    return sin(basis*PI);
  }

  Lattice(LX lx) {
    super(lx);
    addModulator(spin.start());
    addModulator(yClimb.start());
    addParameter(hue);
    addParameter(yHeight);
  }

  public void run(double deltaMs) {
    float spinf = spin.getValuef();
    float coilf = 2*coil(spin.getBasisf());
    for (Cube cube : model.cubes) {
      float wrapdistleft = LXUtils.wrapdistf(cube.theta, spinf + (model.yMax - cube.y) * coilf, 180);
      float wrapdistright = LXUtils.wrapdistf(cube.theta, -spinf - (model.yMax - cube.y) * coilf, 180);
      float width = yClimb.getValuef() + ((cube.y - yHeight.getValuef())/model.yMax) * 50;
      float df = min(100, 3 * max(0, wrapdistleft - width) + 3 * max(0, wrapdistright - width));

      colors[cube.index] = lx.hsb(
        (hue.getValuef() + lx.getBaseHuef() + .2*cube.y - 360) % 360, 
        100, 
        df
      );
    }
  }
}

class Fire extends LXPattern {
  final BasicParameter maxHeight = new BasicParameter("HEIGHT", 0.8, 0.3, 1);
  final BasicParameter flameSize = new BasicParameter("SIZE", 30, 10, 75);  
  final BasicParameter flameCount = new BasicParameter ("FLAMES", 75, 0, 75);
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  
  private int numFlames = 75;
  private Flame[] flames;
  
  private class Flame {
    public float height = 0;
    public float theta = random(0, 360);
    public LinearEnvelope decay = new LinearEnvelope(0,0,0);
  
    public Flame(float maxHeight, boolean groundStart){
      float height = random(0.2, maxHeight);
      decay.setRange(75, model.yMax * height, 1200 * height);
      if (!groundStart) {
        decay.setBasis(random(0,1));
      }
      lx.addModulator(decay.start());
    }
  }

  Fire(LX lx) {
    super(lx);
    addParameter(maxHeight);
    addParameter(flameSize);
    addParameter(flameCount);
    addParameter(hue);

    flames = new Flame[numFlames];
    for (int i = 0; i < numFlames; ++i) {
      flames[i] = new Flame(maxHeight.getValuef(), false);
    }
  }

  public void updateNumFlames(int numFlames) {
    Flame[] newFlames = Arrays.copyOf(flames, numFlames);
    if (flames.length < numFlames) {
      for (int i = flames.length; i < numFlames; ++i) {
        newFlames[i] = new Flame(maxHeight.getValuef(), false);
      }
    }
    flames = newFlames;
  }

  public void run(double deltaMs) {
    numFlames = (int) flameCount.getValuef();
    if (flames.length != numFlames) {
      updateNumFlames(numFlames);
    }
    for (int i = 0; i < flames.length; ++i) {
      if (flames[i].decay.finished()) {
        lx.removeModulator(flames[i].decay);
        flames[i] = new Flame(maxHeight.getValuef(), true);
      }
    }

    for (Cube cube: model.cubes) {
      float yn = cube.y / model.yMax;
      float cBrt = 0;
      float cHue = 0;
      float flameWidth = flameSize.getValuef();
      for (int i = 0; i < flames.length; ++i) {
        if (abs(flames[i].theta - cube.theta) < (flameWidth * (1- yn))) {
          cBrt = min(100, max(0, 100 + cBrt- 2 * abs(cube.y - flames[i].decay.getValuef()) - flames[i].decay.getBasisf() * 25)) ;
          cHue = max(0,  (cHue + cBrt * 0.7) * 0.5);
        }
      }
      colors[cube.index] = lx.hsb(
        (cHue + hue.getValuef()) % 360,
        100,
        min(100, cBrt + (1- yn)* (1- yn) * 50)
      );
    }
  }
}

class BouncyBalls extends LXPattern {
  final BasicParameter ballCount = new BasicParameter("NUM", 10, 1, 25);
  final BasicParameter maxRadius = new BasicParameter("RAD", 50, 5, 100);
  final BasicParameter maxBounce = new BasicParameter("MAXBOUNCE", 0.9, 0, 1);
  final BasicParameter minBounce = new BasicParameter("MINBOUNCE", 0.5, 0, 1);
  final BasicParameter acceleration = new BasicParameter("ACCEL", 400, 0, 1000); 
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
    
  private int numBalls = 10;
  private Ball[] balls;
  
  private class Ball {
    public float theta = random(0, 360);
    public float bHue = random(0, 25);
    public Accelerator gravity = new Accelerator(model.yMax,0,0);
    public float radius = 0;
    
    public Ball(float maxRadius, boolean starterBall) {
      radius = random(5, maxRadius);
      gravity.setAcceleration(-acceleration.getValuef());
      if (starterBall) {
        gravity.setValue(random(0, model.yMax));
      }
      lx.addModulator(gravity.start());
    }
  }
  
  BouncyBalls(LX lx) {
    super(lx);
    addParameter(ballCount);
    addParameter(maxRadius);
    addParameter(maxBounce);
    addParameter(minBounce);
    addParameter(acceleration);
    addParameter(hue);
    
    balls = new Ball[numBalls];
    for (int i = 0; i < numBalls; ++i) {
      balls[i] = new Ball(maxRadius.getValuef(), true);
    }
  }
  
  public void updateNumBalls(int numBalls) {
    Ball[] newBalls = Arrays.copyOf(balls, numBalls);
    if (balls.length < numBalls) {
      for (int i = balls.length; i < numBalls; ++i) {
        newBalls[i] = new Ball(maxRadius.getValuef(), false);
      }
    }
    balls = newBalls;
  }
  
  public void run(double deltaMs) {
    for (int i = 0; i < balls.length; ++i) {
      if (balls[i].gravity.getValuef() > model.yMax) {
        balls[i].gravity.setValue(model.yMax);
      }
    }
    
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        0,
        0,
        0
      );
    }
    numBalls = (int) ballCount.getValuef();
    if (balls.length != numBalls) {
      updateNumBalls(numBalls);
    }
    for (int i = 0; i < balls.length; ++i) {
      float gravVel = balls[i].gravity.getVelocityf();
      float gravVal = balls[i].gravity.getValuef();
      
      if (abs(gravVel) < 1 && gravVal < 20) { //destroy finished balls
        lx.removeModulator(balls[i].gravity);
        balls[i] = new Ball(maxRadius.getValuef(), false);
      }
      
      if (gravVal < 0) { //bounce!
          balls[i].gravity.setValue(-gravVal);
          balls[i].gravity.setVelocity(-gravVel * random(minBounce.getValuef(), maxBounce.getValuef()));
      }
      for (Cube cube : model.cubes) {
        float dist = sqrt(pow((LXUtils.wrapdistf(balls[i].theta, cube.theta, 360)) * 0.8, 2) + pow(balls[i].gravity.getValuef() - (cube.y - model.yMin), 2));
        if (dist < balls[i].radius) {
          colors[cube.index] = lx.hsb(
            (balls[i].bHue + hue.getValuef()) % 360,
            100,
            constrain(cube.y/model.yMax * 125 - 50 * (dist/balls[i].radius), 0, 100)
          );
        }
      }
    }
  }
}

class Bubbles extends LXPattern {
  final BasicParameter ballCount = new BasicParameter("NUM", 10, 1, 150);
  final BasicParameter maxRadius = new BasicParameter("RAD", 50, 5, 100);
  final BasicParameter speed = new BasicParameter("ACCEL", 1, -10, 25); 
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
    
  private int numBalls = 10;
  private Bubble[] bubbles;
  
  private class Bubble {
    public float theta = random(0, 360);
    public float bHue = random(0, 30);
    public Accelerator gravity = new Accelerator(random(-50, 0),0,0);
    public float radius = 0;
    public float baseAcceleration = 0;
    
    public Bubble(float maxRadius) {
      radius = random(5, maxRadius);
      baseAcceleration = 100 * random(0.25, 1);
      gravity.setVelocity(random(-10,10)).setAcceleration(baseAcceleration);
      lx.addModulator(gravity.start());
    }
  }
  
  void onParameterChanged(LXParameter parameter) {
    super.onParameterChanged(parameter);
    if (parameter == speed) {
      for (Bubble b : bubbles) {
        b.gravity.setAcceleration(b.baseAcceleration * speed.getValuef());
      }
    }
  }
  
  Bubbles(LX lx) {
    super(lx);
    addParameter(ballCount);
    addParameter(maxRadius);
    addParameter(speed);
    addParameter(hue);
    
    bubbles = new Bubble[numBalls];
    for (int i = 0; i < numBalls; ++i) {
      bubbles[i] = new Bubble(maxRadius.getValuef());
    }
  }
  
  public void updateNumBalls(int numBalls) {
    Bubble[] newBubbless = Arrays.copyOf(bubbles, numBalls);
    if (bubbles.length < numBalls) {
      for (int i = bubbles.length; i < numBalls; ++i) {
        newBubbless[i] = new Bubble(maxRadius.getValuef());
      }
    }
    bubbles = newBubbless;
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        0,
        0,
        0
      );
    }
    numBalls = (int) ballCount.getValuef();
    if (bubbles.length != numBalls) {
      updateNumBalls(numBalls);
    }
    
    for (int i = 0; i < bubbles.length; ++i) {
      float gravVel = bubbles[i].gravity.getVelocityf();
      float gravVal = bubbles[i].gravity.getValuef();
      if (gravVel <= 0) {
        bubbles[i].gravity.setVelocity(0);
      }
      if (abs(gravVal) > model.yMax) { //destroy finished balls
        lx.removeModulator(bubbles[i].gravity);
        bubbles[i] = new Bubble(maxRadius.getValuef());
      }
      for (Cube cube : model.cubes) {
        if (abs(bubbles[i].theta - cube.theta) < bubbles[i].radius && abs(bubbles[i].gravity.getValuef() - (cube.y - model.yMin)) < bubbles[i].radius) {
          float dist = sqrt(pow((LXUtils.wrapdistf(bubbles[i].theta, cube.theta, 360)) * 0.8, 2) + pow(bubbles[i].gravity.getValuef() - (cube.y - model.yMin), 2));
          
          if (dist < bubbles[i].radius) {
            colors[cube.index] = lx.hsb(
              (bubbles[i].bHue + hue.getValuef()) % 360,
              50 + dist/bubbles[i].radius * 50,
              constrain(cube.y/model.yMax * 125 - 50 * (dist/bubbles[i].radius), 0, 100)
            );
          }
        }
      }
    }
  }
}

class Voronoi extends LXPattern {
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0, 5);
  final BasicParameter width = new BasicParameter("WIDTH", 0.75, 0.5, 1.25);
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  final int NUM_SITES = 15;
  private Site[] sites = new Site[NUM_SITES];
  
  private class Site {
    public float theta = 0;
    public float yPos = 0;
    public PVector velocity = new PVector(0,0);
    
    public Site() {
      theta = random(0, 360);
      yPos = random(model.yMin, model.yMax);
      velocity = new PVector(random(-1,1), random(-1,1));
    }
    
    public void move(float speed) {
      theta = (theta + speed * velocity.x) % 360;
      yPos += speed * velocity.y;
      if ((yPos < model.yMin - 20) || (yPos > model.yMax + 20)) {
        velocity.y *= -1;
      }
    }
  }
  
  Voronoi(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(width);
    addParameter(hue);
    for (int i = 0; i < sites.length; ++i) {
      sites[i] = new Site();
    }
  }
  
  public void run(double deltaMs) {
    for (Cube cube: model.cubes) {
      float minDistSq = 1000000;
      float nextMinDistSq = 1000000;
      for (int i = 0; i < sites.length; ++i) {
        if (abs(sites[i].yPos - cube.y) < 150) { //restraint on calculation
          float distSq = pow((LXUtils.wrapdistf(sites[i].theta, cube.theta, 360)), 2) + pow(sites[i].yPos - cube.y, 2);
          if (distSq < nextMinDistSq) {
            if (distSq < minDistSq) {
              nextMinDistSq = minDistSq;
              minDistSq = distSq;
            } else {
              nextMinDistSq = distSq;
            }
          }
        }
      }
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + hue.getValuef()) % 360,
        100,
        max(0, min(100, 100 - sqrt(nextMinDistSq - minDistSq) / width.getValuef()))
      );
    }
    for (Site site: sites) {
      site.move(speed.getValuef());
    }
  }
}

class Fumes extends LXPattern {
  final BasicParameter speed = new BasicParameter("SPEED", 2, 0, 8);
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  final int NUM_SITES = 15;
  private Site[] sites = new Site[NUM_SITES];
  
  private class Site {
    public float theta = 0;
    public float yPos = 0;
    public PVector velocity = new PVector(0,0);
    
    public Site() {
      theta = random(0, 360);
      yPos = random(model.yMin, model.yMax);
      velocity = new PVector(random(-1,1), random(0,1));
    }
    
    public void move(float speed) {
      theta = (theta + speed * velocity.x) % 360;
      yPos += speed * velocity.y;
      if (yPos < model.yMin - 20) {
        velocity.y *= -1;
      }
      if (yPos > model.yMax + 50) {
        yPos = model.yMin - 10;
      }
    }
  }
  
  Fumes(LX lx) {
    super(lx);
    addParameter(hue);
    addParameter(speed);
    for (int i = 0; i < sites.length; ++i) {
      sites[i] = new Site();
    }
  }
  
  public void run(double deltaMs) {
    for (Cube cube: model.cubes) {
      float minDistSq = 1000000;
      float nextMinDistSq = 1000000;
      for (int i = 0; i < sites.length; ++i) {
        if (abs(sites[i].yPos - cube.y) < 150) { //restraint on calculation
          float distSq = pow((LXUtils.wrapdistf(sites[i].theta, cube.theta, 360)), 2) + pow(sites[i].yPos - cube.y, 2);
          if (distSq < nextMinDistSq) {
            if (distSq < minDistSq) {
              nextMinDistSq = minDistSq;
              minDistSq = distSq;
            } else {
              nextMinDistSq = distSq;
            }
          }
        }
      }
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + hue.getValuef()) % 360,
        100,
        max(0, 100 - sqrt(nextMinDistSq - minDistSq * 0.05))
      );
    }
    for (Site site: sites) {
      site.move(speed.getValuef());
    }
  }
}

class Pulley extends LXPattern implements TriggerablePattern{ //ported from SugarCubes
  final int NUM_DIVISIONS = 2;
  private final Accelerator[] gravity = new Accelerator[NUM_DIVISIONS];
  private final float[] baseSpeed = new float[NUM_DIVISIONS];
  private final Click[] delays = new Click[NUM_DIVISIONS];
   private final Click turnOff = new Click(9000);

  private boolean isRising = false;
  boolean triggered = true;
  float coil = 10;

  private BasicParameter sz = new BasicParameter("SIZE", 0.5);
  private BasicParameter beatAmount = new BasicParameter("BEAT", 0);
  private BooleanParameter automated = new BooleanParameter("AUTO", true);
  private BasicParameter speed = new BasicParameter("SPEED", 1, -3, 3);
  

  Pulley(LX lx) {
    super(lx);
    for (int i = 0; i < NUM_DIVISIONS; ++i) {
      addModulator(gravity[i] = new Accelerator(0, 0, 0));
      addModulator(delays[i] = new Click(0));
    }
    addParameter(sz);
    addParameter(beatAmount);
    addParameter(speed);
    addParameter(automated);
    onParameterChanged(speed);
    addModulator(turnOff);
  }

  void onParameterChanged(LXParameter parameter) {
    super.onParameterChanged(parameter);
    if (parameter == speed && isRising) {
      for (int i = 0; i < NUM_DIVISIONS; ++i) {
        gravity[i].setVelocity(baseSpeed[i] * speed.getValuef());
      }
    }
    if (parameter == automated) {
      if (automated.isOn()) {
        trigger();
      }
    }
  }
  
  private void trigger() {
    isRising = !isRising;
    int i = 0;
    for (int j = 0; j < NUM_DIVISIONS; ++j) {
      if (isRising) {
        baseSpeed[j] = random(20, 33);
        gravity[j].setSpeed(baseSpeed[j], 0).start();
      } 
      else {
        gravity[j].setVelocity(0).setAcceleration(-420);
        delays[j].setDuration(random(0, 500)).trigger();
      }
      ++i;
    }
  }

  public void run(double deltaMS) {
    if (turnOff.click()) {
      triggered = false;
      setColors(lx.hsb(0,0,0));
      turnOff.stopAndReset();      
    }
    if(triggered) {
      if (!isRising) {
        int j = 0;
        for (Click d : delays) {
          if (d.click()) {
            gravity[j].start();
            d.stop();
          }
          ++j;
        }
        for (Accelerator g : gravity) {
          if (g.getValuef() < 0) { //bounce
            g.setValue(-g.getValuef());
            g.setVelocity(-g.getVelocityf() * random(0.74, 0.84));
          }
        }
      }
  
      float fPos = 1 -lx.tempo.rampf();
      if (fPos < .2) {
        fPos = .2 + 4 * (.2 - fPos);
      }
  
      float falloff = 100. / (3 + sz.getValuef() * 36 + fPos * beatAmount.getValuef()*48);
      for (Cube cube : model.cubes) {
        int gi = (int) constrain((cube.x - model.xMin) * NUM_DIVISIONS / (model.xMax - model.xMin), 0, NUM_DIVISIONS-1);
        float yn =  cube.y/model.yMax;
        colors[cube.index] = lx.hsb(
          (lx.getBaseHuef() + abs(cube.x - model.cx)*.8 + cube.y*.4) % 360, 
          constrain(100 *(0.8 -  yn * yn), 0, 100), 
          max(0, 100 - abs(cube.y/2 - 50 - gravity[gi].getValuef())*falloff)
        );
      }
    }
  }

  public void enableTriggerableMode() {
    triggered = false;
  }

  public void onTriggered(float strength) {
    triggered = true;
    isRising = true;
    turnOff.start();
    
    for (Accelerator g: gravity) {
      g.setValue(225);
    }
    trigger();
  }

  public void onRelease() {
  }
}


class Springs extends LXPattern {
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  private BooleanParameter automated = new BooleanParameter("AUTO", true);
  private final Accelerator gravity = new Accelerator(0, 0, 0);
  private final Click reset = new Click(9600);
  private boolean isRising = false;
  final SinLFO spin = new SinLFO(0, 360, 9600);
  
  float coil(float basis) {
    return 4 * sin(basis*TWO_PI + PI) ;
  }

  Springs(LX lx) {
    super(lx);
    addModulator(gravity);
    addModulator(reset).start();
    addModulator(spin.start());
    addParameter(hue);
    addParameter(automated);
    trigger();
  }

  void onParameterChanged(LXParameter parameter) {
    super.onParameterChanged(parameter);
    if (parameter == automated) {
      if (automated.isOn()) {
        trigger();
      }
    }
  }  

  private void trigger() {
    isRising = !isRising;
    if (isRising) {
      gravity.setSpeed(0.25, 0).start();
    } 
    else {
      gravity.setVelocity(0).setAcceleration(-1.75);
    }
  }

  public void run(double deltaMS) {
    if (!isRising) {
      gravity.start();
      if (gravity.getValuef() < 0) {
        gravity.setValue(-gravity.getValuef());
        gravity.setVelocity(-gravity.getVelocityf() * random(0.74, 0.84));
      }
    }

    float spinf = spin.getValuef();
    float coilf = 2*coil(spin.getBasisf());
    
    for (Cube cube : model.cubes) {
      float yn =  cube.y/model.yMax;
      float width = (1-yn) * 25;
      float wrapdist = LXUtils.wrapdistf(cube.theta, spinf + (cube.y) * 1/(gravity.getValuef() + 0.2), 360);
      float df = max(0, 100 - max(0, wrapdist-width));
      colors[cube.index] = lx.hsb(
        max(0, (lx.getBaseHuef() - yn * 20 + hue.getValuef()) % 360), 
        constrain((1- yn) * 100 + wrapdist, 0, 100),
        max(0, df - yn * 50)
      );
    }
  }
}

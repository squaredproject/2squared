import ddf.minim.*;

class Fireflies extends LXPattern {
  final DiscreteParameter flyCount = new DiscreteParameter("NUM", 20, 1, 100);
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0, 7.5); 
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  private float radius = 40;
  private int numFireflies = 20;
  private Firefly[] fireflies;
  private Firefly[] queue;
  private SinLFO[] blinkers = new SinLFO[10];
  
  
  private class Firefly {
    public float theta = 0;
    public float yPos = 0;
    public PVector velocity = new PVector(0,0);
    public float radius = 0;
    public int blinkIndex = 0;

    public Firefly() {
      theta = random(0, 360);
      yPos = random(model.yMin, model.yMax);
      velocity = new PVector(random(-1,1), random(0.25, 1));
      radius = 30;
      blinkIndex = (int) random(0, blinkers.length);
    }

    public void move(float speed) {
      theta = (theta + speed * velocity.x) % 360;
      yPos += speed * velocity.y;

    }
  }
  
  Fireflies(LX lx) {
    super(lx);
    addParameter(flyCount);
    addParameter(speed);
    addParameter(hue);

    for (int i = 0; i < blinkers.length; ++i) {
      blinkers[i] = new SinLFO(0, 75, 1000  * random(1.0, 3.0));      
      addModulator(blinkers[i].start().setValue(random(0,50)));
    }
    
    fireflies = new Firefly[numFireflies];
    queue = new Firefly[0];
    for (int i = 0; i < numFireflies; ++i) {
      fireflies[i] = new Firefly();
    }
  }
  
  public void addToQueue(int numFlies) {
    int oldQueueLength = queue.length;
    queue = Arrays.copyOf(queue, oldQueueLength + numFlies);
    for (int i = oldQueueLength; i < queue.length; ++i) {
      queue[i] = new Firefly();
    }
  }

  public Firefly removeFromQueue(int index) {
    Firefly[] newQueue = Arrays.copyOf(queue, queue.length - 1);
    for (int i = index; i < newQueue.length; ++i) {
      newQueue[i] = queue[i + 1];
    }
    Firefly addedFly = queue[index];
    queue = newQueue;
    return addedFly;
  }

  public void addFirefly(Firefly fly) {
    Firefly[] newFireflies = Arrays.copyOf(fireflies, fireflies.length + 1);
    newFireflies[newFireflies.length - 1] = fly;
    fireflies = newFireflies;
  }
  
  public void removeFirefly(int index) {
    Firefly[] newFireflies = Arrays.copyOf(fireflies, fireflies.length - 1);
    for (int i = index; i < newFireflies.length; ++i) {
      newFireflies[i] = fireflies[i + 1];
    }
    fireflies = newFireflies;
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        0,
        0,
        0
      );
    }

    numFireflies = flyCount.getValuei();

    if (fireflies.length < numFireflies) { 
      addToQueue(numFireflies - fireflies.length);
    }

    for (int i = 0; i < queue.length; ++i) { //only add fireflies when they're about to blink on
      if (blinkers[queue[i].blinkIndex].getValuef() > 70) {
        addFirefly(removeFromQueue(i));
      }
    }

    for (int i = 0; i < fireflies.length; ++i) { //remove fireflies while blinking off
      if (numFireflies < fireflies.length) {
        if (blinkers[fireflies[i].blinkIndex].getValuef() > 70) {
          removeFirefly(i);
        }
      }
    }

    for (int i = 0; i < fireflies.length; ++i) {
      if (fireflies[i].yPos > model.yMax + radius) {
          fireflies[i].yPos = model.yMin - radius;
      }
    }

    for (Firefly fly:fireflies) {
      for (Cube cube: model.cubes) {
        if (abs(fly.yPos - cube.y) <= radius && abs(fly.theta - cube.theta) <= radius) {
          float distSq = pow((LXUtils.wrapdistf(fly.theta, cube.theta, 360)), 2) + pow(fly.yPos - cube.y, 2);
          float brt = max(0, 100 - sqrt(distSq * 4) - blinkers[fly.blinkIndex].getValuef());
          if (brt > lx.b(colors[cube.index])) {
            colors[cube.index] = lx.hsb(
              (lx.getBaseHuef() + hue.getValuef()) % 360,
              100 - brt,
              brt
            );
          }
        }
      }
    }

    for (Firefly firefly: fireflies) {
      firefly.move(speed.getValuef());
    }
  }
}

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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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

class Bubbles extends LXPattern {
  final DiscreteParameter ballCount = new DiscreteParameter("NUM", 10, 1, 150);
  final BasicParameter maxRadius = new BasicParameter("RAD", 50, 5, 100);
  final BasicParameter speed = new BasicParameter("SPEED", 1, 0, 5); 
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
    
  private int numBubbles = 10;
  private Bubble[] bubbles;
  
  private class Bubble {
    public float theta = 0;
    public float yPos = 0;
    public float bHue = 0;
    public float baseSpeed = 0;
    public float radius = 0;

    public Bubble(float maxRadius) {
      theta = random(0, 360);
      bHue = random(0, 30);
      baseSpeed = random(2, 5);
      radius = random(5, maxRadius);
      yPos = model.yMin - radius * random(1,10);
    }

    public void move(float speed) {
      yPos += baseSpeed * speed;
    }
  }
  
  Bubbles(LX lx) {
    super(lx);
    addParameter(ballCount);
    addParameter(maxRadius);
    addParameter(speed);
    addParameter(hue);
    
    bubbles = new Bubble[numBubbles];
    for (int i = 0; i < numBubbles; ++i) {
      bubbles[i] = new Bubble(maxRadius.getValuef());
    }
  }
  
  public void addBubbles(int numBubbles) {
    Bubble[] newBubbles = Arrays.copyOf(bubbles, numBubbles);
    for (int i = bubbles.length; i < numBubbles; ++i) {
      newBubbles[i] = new Bubble(maxRadius.getValuef());
    }
    bubbles = newBubbles;
  }
  
  public void removeBubble(int index) {
    Bubble[] newBubbles = Arrays.copyOf(bubbles, bubbles.length - 1);
    for (int i = index; i < newBubbles.length; ++i) {
      newBubbles[i] = bubbles[i + 1];
    }
    bubbles = newBubbles;
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        0,
        0,
        0
      );
    }

    numBubbles = ballCount.getValuei();
    if (bubbles.length < numBubbles) {
      addBubbles(numBubbles);
    }
    
    for (int i = 0; i < bubbles.length; ++i) {
      if (bubbles[i].yPos > model.yMax + bubbles[i].radius) { //bubble is now off screen
        if (numBubbles < bubbles.length) {
          removeBubble(i);
        } else {
          bubbles[i] = new Bubble(maxRadius.getValuef());
        }
      }
    }
      
    for (Bubble bubble: bubbles) {
      for (Cube cube : model.cubes) {
        if (abs(bubble.theta - cube.theta) < bubble.radius && abs(bubble.yPos - (cube.y - model.yMin)) < bubble.radius) {
          float distTheta = LXUtils.wrapdistf(bubble.theta, cube.theta, 360) * 0.8;
          float distY = bubble.yPos - (cube.y - model.yMin);
          float distSq = distTheta * distTheta + distY * distY;
          
          if (distSq < bubble.radius * bubble.radius) {
            float dist = sqrt(distSq);
            colors[cube.index] = lx.hsb(
              (bubble.bHue + hue.getValuef()) % 360,
              50 + dist/bubble.radius * 50,
              constrain(cube.y/model.yMax * 125 - 50 * (dist/bubble.radius), 0, 100)
            );
          }
        }
      }
    
      bubble.move(speed.getValuef());
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
    if (getChannel().getFader().getNormalized() == 0) return;

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
  final BasicParameter speed = new BasicParameter("SPEED", 2, 0, 20);
  final BasicParameter hue = new BasicParameter("HUE", 0, 0, 360);
  final BasicParameter sat = new BasicParameter("SAT", 25, 0, 100);
  final int NUM_SITES = 15;
  private Site[] sites = new Site[NUM_SITES];
  
  private class Site {
    public float theta = 0;
    public float yPos = 0;
    public PVector velocity = new PVector(0,0);
    
    public Site() {
      theta = random(0, 360);
      yPos = random(model.yMin, model.yMax);
      velocity = new PVector(random(0,1), random(0,0.75));
    }
    
    public void move(float speed) {
      theta = (theta + speed * velocity.x) % 360;
      yPos += speed * velocity.y;
      if (yPos < model.yMin - 50) {
        velocity.y *= -1;
      }
      if (yPos > model.yMax + 50) {
        yPos = model.yMin - 50;
      }
    }
  }
  
  Fumes(LX lx) {
    super(lx);
    addParameter(hue);
    addParameter(speed);
    addParameter(sat);
    for (int i = 0; i < sites.length; ++i) {
      sites[i] = new Site();
    }
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
    
    float minSat = sat.getValuef();
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
      float brt = max(0, 100 - sqrt(nextMinDistSq));
      colors[cube.index] = lx.hsb(
        (lx.getBaseHuef() + hue.getValuef()) % 360,
        100 - min( minSat, brt),
        brt
      );
    }
    for (Site site: sites) {
      site.move(speed.getValuef());
    }
  }
}

class Pulley extends LXPattern implements Triggerable { //ported from SugarCubes
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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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

class Pulleys extends LXPattern implements Triggerable{ //ported from SugarCubes
  private BasicParameter sz = new BasicParameter("SIZE", 0.5);
  private BasicParameter beatAmount = new BasicParameter("BEAT", 0);
  private BooleanParameter automated = new BooleanParameter("AUTO", true);
  private BasicParameter speed = new BasicParameter("SPEED", 1, -3, 3);
  private final Click turnOff = new Click(9000);
  final DiscreteParameter pulleyCount = new DiscreteParameter("NUM", 1, 1, 5);

  private boolean isRising = false; //are the pulleys rising or falling
  boolean triggered = true; //has the trigger to rise/fall been pulled
  boolean autoMode = true; //triggerMode vs autoMode.
  private int numPulleys = 1;
  private Pulley[] pulleys = new Pulley[numPulleys];
  

  private class Pulley {
    public float baseSpeed = 0;
    public Click delay = new Click(0);
    public Click turnOff = new Click(9000);
    public final Accelerator gravity = new Accelerator(0,0,0);
    public float baseHue = 0;
    public LinearEnvelope maxBrt = new LinearEnvelope(0,0,0);
    
    public Pulley() {
      baseSpeed = random(10,50);
      baseHue = random(0, 30);
      delay.setDuration(random(0,500));
      gravity.setSpeed(this.baseSpeed, 0);
      maxBrt.setRange(0,1,3000);
      lx.addModulator(gravity);
      lx.addModulator(delay);
      lx.addModulator(maxBrt.start());
    }
  }

  Pulleys(LX lx) {
    super(lx);
    addParameter(sz);
    addParameter(beatAmount);
    addParameter(speed);
    addParameter(automated);
    addParameter(pulleyCount);
    onParameterChanged(speed);
    // addModulator(turnOff);

    for (int i = 0; i < pulleys.length; i++) {
      pulleys[i] = new Pulley();
    } 
  }

  void onParameterChanged(LXParameter parameter) {
    super.onParameterChanged(parameter);
    if (parameter == speed && isRising) {
      for (int i = 0; i < pulleys.length; i++) {
        pulleys[i].gravity.setVelocity(pulleys[i].baseSpeed * speed.getValuef());
      }
    }
    if (parameter == automated) {
      if (automated.isOn()) {
        trigger();
      }
    }
  }

  private void trigger() {
    if (autoMode) {
      isRising = !isRising;
    }
    for (int j = 0; j < pulleys.length; j++) {
      if (isRising) {
        pulleys[j].gravity.setSpeed(pulleys[j].baseSpeed,0).start();
      } 
      else {
        pulleys[j].gravity.setVelocity(0).setAcceleration(-420);
        pulleys[j].delay.trigger();
      }
    }
  }

  public void run(double deltaMS) {
    if (getChannel().getFader().getNormalized() == 0) return;
    
    if (autoMode) {
      numPulleys = pulleyCount.getValuei();
      
      if (numPulleys < pulleys.length) {
        for (int i = numPulleys; i < pulleys.length; i++) {
          pulleys[i].maxBrt.start();
        }
      }
      
      if (numPulleys > pulleys.length) {
        addPulleys(numPulleys);
      }
    }
    
    for (int i = 0; i < pulleys.length; i++) {
      if (pulleys[i].maxBrt.finished()) {
        if (pulleys[i].maxBrt.getValuef() == 1) {
          pulleys[i].maxBrt.setRange(1,0,3000).reset();
        } else {
          removePulley(i);
        }
      }
    }

    for (int i = 0; i < pulleys.length; i++) {
      if (pulleys[i].turnOff.click()) {
        pulleys[i].maxBrt.start();
      }
    }
    
    if(triggered) {
      if (!isRising) {
        for (int j = 0; j < pulleys.length; ++j) {
          if (pulleys[j].delay.click()) {
            pulleys[j].gravity.start();
            pulleys[j].delay.stop();
          }
          if (pulleys[j].gravity.getValuef() < 0) { //bouncebounce
            pulleys[j].gravity.setValue(-pulleys[j].gravity.getValuef());
            pulleys[j].gravity.setVelocity(-pulleys[j].gravity.getVelocityf() * random(0.74,0.84));
          }
        }
      }
  
      float fPos = 1 -lx.tempo.rampf();
      if (fPos < .2) {
        fPos = .2 + 4 * (.2 - fPos);
      }
  
      float falloff = 100. / (3 + sz.getValuef() * 36 + fPos * beatAmount.getValuef()*48);
      for (Cube cube : model.cubes) {
        float cBrt = 0;
        float cHue = 0;
        for (int j = 0; j < pulleys.length; ++j) {
          cHue = (lx.getBaseHuef() + abs(cube.x - model.cx)*.8 + cube.y*.4 + pulleys[j].baseHue) % 360;
          cBrt += max(0, pulleys[j].maxBrt.getValuef() * (100 - abs(cube.y/2 - 50 - pulleys[j].gravity.getValuef())*falloff));
        }
        float yn =  cube.y/model.yMax;
        colors[cube.index] = lx.hsb(
          cHue, 
          constrain(100 *(0.8 -  yn * yn), 0, 100), 
          min(100, cBrt)
        );
      }
    }
  }

  public void addPulleys(int numPulleys) {
    Pulley[] newPulleys = Arrays.copyOf(pulleys, numPulleys);
    for (int i = pulleys.length; i < numPulleys; ++i) {
      Pulley newPulley = new Pulley();
      if (isRising) {
        newPulley.gravity.setSpeed(newPulley.baseSpeed,0).start();
      } else {
        if (autoMode) {
          newPulley.gravity.setValue(random(0,225));
        } else {
          newPulley.gravity.setValue(225);
        }

        newPulley.gravity.setVelocity(0).setAcceleration(-420);
        newPulley.delay.trigger();
      }
      newPulleys[i] = newPulley;
    }
    pulleys = newPulleys;
  }

  public void removePulley(int index) {
    Pulley[] newPulleys = Arrays.copyOf(pulleys, pulleys.length - 1);
    Pulley pulley = pulleys[index];

    for (int i = index; i < newPulleys.length; ++i) {
      newPulleys[i] = pulleys[i+1];
    }
    pulleys = newPulleys;
    lx.removeModulator(pulley.turnOff);
    lx.removeModulator(pulley.gravity);
    lx.removeModulator(pulley.maxBrt);
  }

  public void enableTriggerableMode() {
    autoMode = false;
    isRising = true;
    trigger();
  }

  public void onTriggered(float strength) {
    addPulleys(pulleys.length + 1);    
  }
  
  public void onRelease() {
  }
}






int WHITE = java.awt.Color.WHITE.getRGB();
int BLACK = java.awt.Color.BLACK.getRGB();

class BassSlam extends LXPattern {
  
  final static int SLAM_STATE_1 = 1 << 0;
  final static int SLAM_STATE_2 = 1 << 1;
  
  int state = SLAM_STATE_1;
  double timer = 0;
  
  BassSlam(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    timer += deltaMs;
    switch(state) {
      case SLAM_STATE_1:
        float time = (float)(timer / 500);
        float y;
        if (time < 1) {
          y = 1 + pow(time + 0.16, 2) * sin(18 * (time + 0.16)) / 4;
        } else {
          y = 1.32 - 20 * pow(time - 1, 2);
        }
        y = 100 * (y - 1) + 250;
        if (y <= 0) {
          state = SLAM_STATE_2;
          timer = 0;
          y = 0;
        }
        
        for (Cube cube : model.cubes) {
          setColor(cube.index, lx.hsb(200, 100, LXUtils.constrainf(100 - 2 * abs(y - cube.y), 0, 100)));
        }
        break;
      case SLAM_STATE_2:
        if (timer >= 20) {
          state = SLAM_STATE_1;
          timer = 0;
        }
        setColors(lx.hsb(200, 100, 100));
        break;
    }
  }
}

abstract class MultiObjectPattern <ObjectType extends MultiObject> extends LXPattern implements TriggerablePattern, KeyboardPlayablePattern {
  
  BasicParameter frequency;
  
  final boolean shouldAutofade;
  
  final ArrayList<ObjectType> objects;
  double pauseTimerCountdown = 0;
  boolean triggered = true;
  boolean keyboardMode = false;
  float modWheelValue = 0;
//  BasicParameter fadeLength
  
  MultiObjectPattern(LX lx) {
    this(lx, true);
  }
  
  MultiObjectPattern(LX lx, boolean shouldAutofade) {
    super(lx);
    
    frequency = getFrequencyParameter();
    addParameter(frequency);
    
    this.shouldAutofade = shouldAutofade;
//    if (shouldAutofade) {
      
    
    objects = new ArrayList<ObjectType>();
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", .5, .1, 40, BasicParameter.Scaling.QUAD_IN);
  }
  
//  BasicParameter getAutofadeParameter() {
//    return new BasicParameter("TAIL", 
//  }
  
  public void run(double deltaMs) {
    if (triggered && !keyboardMode && objects.size() < ceil(frequency.getValuef())) {
      int missing = ceil(frequency.getValuef()) - objects.size();
      pauseTimerCountdown -= deltaMs;
      if (pauseTimerCountdown <= 0 || missing >= 5) {
        pauseTimerCountdown = (frequency.getValuef() < 1 ? 500 * (1 / frequency.getValuef() - 1) : 0)
                              + (missing == 1 ? random(200) : random(50));
        for (int i = ceil(missing / 3.); i > 0; i--) {
          makeObject(0);
        }
      }
    }
    
    if (shouldAutofade) {
      for (Cube cube : model.cubes) {
        blendColor(cube.index, lx.hsb(0, 0, 100 * max(0, (float)(1 - deltaMs / 1000))), MULTIPLY);
      }
    } else {
      clearColors();
    }
    
    if (objects.size() > 0) {
      Iterator<ObjectType> iter = objects.iterator();
      while (iter.hasNext()) {
        ObjectType object = iter.next();
        if (!object.running) {
          layers.remove(object);
          iter.remove();
        }
      }
    }
  }
  
  void makeObject(float strength) {
    ObjectType object = generateObject(strength);
    object.init();
    addLayer(object);
    objects.add(object);
  }
  
  public void enableTriggerableMode() {
    triggered = false;
  }
  
  public void onTriggered(float strength) {
    triggered = true;
    makeObject(strength);
  }
  
  public void onRelease() {
    triggered = false;
  }
  
  public void enableKeyboardPlayableMode() {
    keyboardMode = true;
  }
  
  public void noteOn(LXMidiNoteOn note) {
    makeObject(note.getPitch());
  }
  
  public void noteOff(LXMidiNoteOff note) {
  }
  
  public void modWheelChanged(float value) {
    modWheelValue = value;
  }
  
  abstract ObjectType generateObject(float strength);
}

abstract class MultiObject extends LXLayer {
  
  boolean running = true;
  
  public void run(double deltaMs, int[] colors) {
    if (running) {
      run(deltaMs);
      if (running) {
        for (Cube cube : model.cubes) {
          colors[cube.index] = blendColor(colors[cube.index], getColorForCube(cube), LIGHTEST);
        }
      }
    }
  }
  
  void init() { }
  void run(double deltaMs) { }
  int getColorForCube(Cube cube) { return BLACK; }
  float getRunningTimeEstimate() { return 1000; }
}

class Explosions extends MultiObjectPattern<Explosion> {
  
  ArrayList<Explosion> explosions;
  
  Explosions(LX lx) {
    super(lx, false);
    
    explosions = new ArrayList<Explosion>();
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", .50, .1, 20, BasicParameter.Scaling.QUAD_IN);
  }
  
  Explosion generateObject(float strength) {
    Explosion explosion = new Explosion();
    explosion.origin = new PVector(random(360), (float)LXUtils.random(model.yMin + 50, model.yMax - 50));
    explosion.hue = (int)(keyboardMode ? (360 * modWheelValue) : random(360));
    return explosion;
  }
}

class Explosion extends MultiObject {
  
  final static int EXPLOSION_STATE_IMPLOSION_EXPAND = 1 << 0;
  final static int EXPLOSION_STATE_IMPLOSION_WAIT = 1 << 1;
  final static int EXPLOSION_STATE_IMPLOSION_CONTRACT = 1 << 2;
  final static int EXPLOSION_STATE_FLASH = 1 << 3;
  final static int EXPLOSION_STATE_EXPLOSION = 1 << 4;
  
  PVector origin;
  int hue;
  
  float accelOfImplosion = 3000;
  Accelerator implosionRadius;
  float implosionWaitTimer = 100;
  Accelerator explosionRadius;
  LXModulator explosionFade;
  float explosionThetaOffset;
  float flashTimer = 50;
  
  int state = EXPLOSION_STATE_IMPLOSION_EXPAND;
  
  void init() {
    explosionThetaOffset = random(360);
    implosionRadius = new Accelerator(0, 700, -accelOfImplosion);
    lx.addModulator(implosionRadius.start());
    explosionFade = new LinearEnvelope(1, 0, 1000);
  }
  
  public void run(double deltaMs) {
    switch (state) {
      case EXPLOSION_STATE_IMPLOSION_EXPAND:
        if (implosionRadius.getVelocityf() <= 0) {
          state = EXPLOSION_STATE_IMPLOSION_WAIT;
          implosionRadius.stop();
        }
        break;
      case EXPLOSION_STATE_IMPLOSION_WAIT:
        implosionWaitTimer -= deltaMs;
        if (implosionWaitTimer <= 0) {
          state = EXPLOSION_STATE_IMPLOSION_CONTRACT;
          implosionRadius.setAcceleration(-8000);
          implosionRadius.start();
        }
        break;
      case EXPLOSION_STATE_IMPLOSION_CONTRACT:
        if (implosionRadius.getValuef() < 0) {
//          state = EXPLOSION_STATE_FLASH;
          lx.removeModulator(implosionRadius.stop());
          state = EXPLOSION_STATE_EXPLOSION;
          explosionRadius = new Accelerator(0, -implosionRadius.getVelocityf(), -300);
          lx.addModulator(explosionRadius.start());
          lx.addModulator(explosionFade.start());
        }
        break;
      case EXPLOSION_STATE_FLASH:
        flashTimer -= deltaMs;
        if (flashTimer <= 0) {
          state = EXPLOSION_STATE_EXPLOSION;
          explosionRadius = new Accelerator(0, -implosionRadius.getVelocityf(), -300);
          lx.addModulator(explosionRadius.start());
          lx.addModulator(explosionFade.start());
        }
        break;
      default:
        if (explosionFade.getValuef() <= 0) {
          running = false;
          lx.removeModulator(explosionRadius.stop());
          lx.removeModulator(explosionFade.stop());
        }
        break;
    }
  }
  
  int getColorForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(origin, cube.cylinderPoint);
    float dist = origin.dist(cubePointPrime);
    switch (state) {
      case EXPLOSION_STATE_IMPLOSION_EXPAND:
      case EXPLOSION_STATE_IMPLOSION_WAIT:
      case EXPLOSION_STATE_IMPLOSION_CONTRACT:
        return lx.hsb(hue, 100, 100 * LXUtils.constrainf((implosionRadius.getValuef() - dist) / 10, 0, 1));
      case EXPLOSION_STATE_FLASH:
        return lx.hsb(hue, 100, 20);
      default:
        float theta = explosionThetaOffset + PVector.sub(cubePointPrime, origin).heading() * 180 / PI + 360;
        return lx.hsb(hue, 100, 100
            * LXUtils.constrainf(1 - (dist - explosionRadius.getValuef()) / 10, 0, 1)
            * LXUtils.constrainf(1 - (explosionRadius.getValuef() - dist) / 200, 0, 1)
            * LXUtils.constrainf((1 - abs(theta % 30 - 15) / 100 / asin(20 / max(20, dist))), 0, 1)
            * explosionFade.getValuef());
    }
  }
}

class Wisps extends MultiObjectPattern<Wisp> {
  
  final BasicParameter baseColor = new BasicParameter("COLR", 210, 360);
  final BasicParameter colorVariability = new BasicParameter("CVAR", 10, 180);
  final BasicParameter direction = new BasicParameter("DIR", 90, 360);
  final BasicParameter directionVariability = new BasicParameter("DVAR", 20, 180);
  final BasicParameter thickness = new BasicParameter("WIDT", 3.5, 1, 20, BasicParameter.Scaling.QUAD_IN);
  final BasicParameter speed = new BasicParameter("SPEE", 10, 1, 20, BasicParameter.Scaling.QUAD_IN);

  // Possible other parameters:
  //  Distance
  //  Distance variability
  //  width variability
  //  Speed variability
  //  frequency variability
  //  Fade time
  
  Wisps(LX lx) {
    super(lx);
    
    addParameter(baseColor);
    addParameter(colorVariability);
    addParameter(direction);
    addParameter(directionVariability);
    addParameter(thickness);
    addParameter(speed);
  }
    
  Wisp generateObject(float strength) {
    Wisp wisp = new Wisp();
    wisp.runningTimer = 0;
    wisp.runningTimerEnd = 5000 / speed.getValuef();
    float pathDirection = (float)(direction.getValuef()
      + LXUtils.random(-directionVariability.getValuef(), directionVariability.getValuef())) % 360;
    float pathDist = (float)LXUtils.random(80, min(450, 140 / max(0.01, abs(cos(PI * pathDirection / 180)))));
    float startTheta = random(360);
    float startY = (float)LXUtils.random(max(model.yMin, model.yMin - pathDist * sin(PI * pathDirection / 180)), 
      min(model.yMax, model.yMax - pathDist * sin(PI * pathDirection / 180)));
    wisp.startPoint = new PVector(startTheta, startY);
    wisp.endPoint = PVector.fromAngle(pathDirection * PI / 180);
    wisp.endPoint.mult(pathDist);
    wisp.endPoint.add(wisp.startPoint);
    wisp.displayColor = (int)(baseColor.getValuef()
      + LXUtils.random(-colorVariability.getValuef(), colorVariability.getValuef())) % 360;
    wisp.thickness = 10 * thickness.getValuef() + (float)LXUtils.random(-3, 3);
    
    return wisp;
  }
}

class Wisp extends MultiObject {
  
  float runningTimer;
  float runningTimerEnd;
  
  PVector startPoint;
  PVector endPoint;
  
  int displayColor;
  float thickness;
  
  PVector currentPoint;
  
  public void run(double deltaMs) {
    if (running) {
      runningTimer += deltaMs;
      if (runningTimer >= runningTimerEnd) {
        running = false;
      } else {
        currentPoint = PVector.lerp(startPoint, endPoint, runningTimer / runningTimerEnd);
      }
    }
  }
  
  int getColorForCube(Cube cube) {
    return lx.hsb(displayColor, 100, getBrightnessForCube(cube));
  }
  
  float getBrightnessForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(currentPoint, cube.cylinderPoint);
    if (insideOfBoundingBox(currentPoint, cubePointPrime, thickness, thickness)) {
      float dist = PVector.dist(cubePointPrime, currentPoint);
      return 100 * max(0, (1 - dist / thickness));
    } else {
      return 0;
    }
  }
}

boolean insideOfBoundingBox(PVector origin, PVector point, float xTolerance, float yTolerance) {
  return abs(origin.x - point.x) <= xTolerance && abs(origin.y - point.y) <= yTolerance;
}

float wrapDist2d(PVector a, PVector b) {
  return sqrt(pow((LXUtils.wrapdistf(a.x, b.x, 360)), 2) + pow(a.y - b.y, 2));
}

PVector movePointToSamePlane(PVector reference, PVector point) {
  return new PVector(moveThetaToSamePlane(reference.x, point.x), point.y);
}

// Assumes thetaA as a reference point
// Moves thetaB to within 180 degrees, letting thetaB go beyond [0, 360)
float moveThetaToSamePlane(float thetaA, float thetaB) {
  if (thetaA - thetaB > 180) {
    return thetaB + 360;
  } else if (thetaB - thetaA > 180) {
    return thetaB - 360;
  } else {
    return thetaB;
  }
}

// Gets the closest point on a line segment [a, b] to another point p
// Assumes points are in the form (theta, y) and are on a cylinder.
PVector getClosestPointOnLineOnCylinder(PVector a, PVector b, PVector p) {
  // Unwrap the cylinder at 0 degrees to calculate
  // Assume a and b are already on the same plane (aka theta would be negative already)
  
  // Move p onto the same plane as a, if needed
  PVector pPrime = movePointToSamePlane(a, p);;
  
  return getClosestPointOnLine(a, b, pPrime);
}

// Gets the closest point on a line segment [a, b] to another point p
// Assumes points are in the form (theta, y)
PVector getClosestPointOnLineA(PVector a, PVector b, PVector p) {

  if (a.x == b.x) {
    float m = (b.x - a.x) / (b.y - a.y);
    float x = m * p.y + a.x - m * a.y;
  } 
  else {
    float m = (b.y - a.y) / (b.x - a.x);
    float y = m * p.x + a.y - m * a.x;
  }

  return null;
}

// Gets the closest point on a line segment [a, b] to another point p
// Assumes points are in the form (theta, y)
PVector getClosestPointOnLine(PVector a, PVector b, PVector p) {
  
  // adapted from http://stackoverflow.com/a/3122532
  
  // Storing vector A->P
  PVector a_to_p = PVector.sub(p, a);
  // Storing vector A->B
  PVector a_to_b = PVector.sub(b, a);

  //   Basically finding the squared magnitude of a_to_b
  float atb2 = a_to_b.magSq();

  // The dot product of a_to_p and a_to_b
  float atp_dot_atb = a_to_p.dot(a_to_b);

  // The normalized "distance" from a to your closest point
  float t = LXUtils.constrainf(atp_dot_atb / atb2, 0, 1);

  // Add the distance to A, moving towards B
  return PVector.lerp(a, b, t);
}

class Rain extends MultiObjectPattern<RainDrop> {
  
  Rain(LX lx) {
    super(lx);
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", 40, .1, 400, BasicParameter.Scaling.QUAD_IN);
  }
   
  RainDrop generateObject(float strength) {
    RainDrop rainDrop = new RainDrop();
    rainDrop.runningTimer = 0;
    rainDrop.runningTimerEnd = 180 + random(20);
    rainDrop.decayTime = rainDrop.runningTimerEnd;
    float pathDirection = 270;
    rainDrop.pathDist = model.yMax - model.yMin + 40;
    rainDrop.startTheta = random(360);
    rainDrop.startY = model.yMax + 20;
    rainDrop.startPoint = new PVector(rainDrop.startTheta, rainDrop.startY);
    rainDrop.endTheta = rainDrop.startTheta;
    rainDrop.endY = model.yMin - 20;
    rainDrop.displayColor = 200 + (int)random(20);
    rainDrop.thickness = 1.5 + random(.6);
    
    return rainDrop;
  }
}

class RainDrop extends MultiObject {
  
  float runningTimer;
  float runningTimerEnd;
  float decayTime;
  
  PVector startPoint;
  float startTheta;
  float startY;
  float endTheta;
  float endY;
  float pathDist;
  
  int displayColor;
  float thickness;
  
  float percentDone;
  PVector currentPoint;
  float currentTheta;
  float currentY;
  
  public void run(double deltaMs) {
    if (running) {
      runningTimer += deltaMs;
      if (runningTimer >= runningTimerEnd + decayTime) {
        running = false;
      } else {
        percentDone = min(runningTimer, runningTimerEnd) / runningTimerEnd;
        currentTheta = (float)LXUtils.lerp(startTheta, endTheta, percentDone);
        currentY = (float)LXUtils.lerp(startY, endY, percentDone);
        currentPoint = new PVector(currentTheta, currentY);
      }
    }
  }
  
  int getColorForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(currentPoint, cube.cylinderPoint);
    float distFromSource = PVector.dist(cubePointPrime, currentPoint);
    float tailFadeFactor = distFromSource / pathDist;
    return lx.hsb(displayColor, 100, max(0, (100 - 10 * distFromSource / thickness)));
  }
}

class Strobe extends LXPattern implements TriggerablePattern {
  
  final BasicParameter speed = new BasicParameter("SPEE", 200, 3000, 30, BasicParameter.Scaling.QUAD_OUT);
  final BasicParameter balance = new BasicParameter("BAL", .5, .01, .99);

  int timer = 0;
  boolean on = false;
  boolean triggered = true;
  
  Strobe(LX lx) {
    super(lx);
    
    addParameter(speed);
    addParameter(balance);
  }
  
  public void run(double deltaMs) {
    if (triggered) {
      timer += deltaMs;
      if (timer >= speed.getValuef() * (on ? balance.getValuef() : 1 - balance.getValuef())) {
        timer = 0;
        on = !on;
      }
      
      setColors(on ? WHITE : BLACK);
    }
  }
  
  public void enableTriggerableMode() {
    triggered = false;
  }
  
  public void onTriggered(float strength) {
    triggered = true;
    on = true;
  }
  
  public void onRelease() {
    triggered = false;
    timer = 0;
    on = false;
    setColors(BLACK);
  }
}

class Brightness extends LXPattern implements TriggerablePattern {
  
  Brightness(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
  }
  
  public void enableTriggerableMode() {
  }
  
  public void onTriggered(float strength) {
    setColors(lx.hsb(0, 0, 100 * strength));
  }
  
  public void onRelease() {
    setColors(BLACK);
  }
}

class RandomColor extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("Speed", 1, 1, 10);
  
  int frameCount = 0;
  
  RandomColor(LX lx) {
    super(lx);
    addParameter(speed);
  }
  
  public void run(double deltaMs) {
    frameCount++;
    if (frameCount >= speed.getValuef()) {
      for (Cube cube : model.cubes) {
        colors[cube.index] = lx.hsb(
          random(360),
          100,
          100
        );
      }
      frameCount = 0;
    }
  }
}

class RandomColorAll extends LXPattern {
  
  RandomColorAll(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    setColors(lx.hsb(random(360), 100, 100));
  }
}

class RandomColorGlitch extends LXPattern {
  
  RandomColorGlitch(LX lx) {
    super(lx);
  }
  
  final int brokenCubeIndex = (int)random(model.cubes.size());
  final int cubeColor = (int)random(360);
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      if (cube.index == brokenCubeIndex) {
        colors[cube.index] = lx.hsb(
          random(360),
          100,
          100
        );
      } else {
        colors[cube.index] = lx.hsb(
          cubeColor,
          100,
          100
        );
      }
    }
  }
}

class Fade extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEE", 11000, 100000, 1000, BasicParameter.Scaling.QUAD_OUT);
  final BasicParameter smoothness = new BasicParameter("SMOO", 100, 1, 100, BasicParameter.Scaling.QUAD_IN);

  final SinLFO colr = new SinLFO(0, 360, speed);

  Fade(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(smoothness);
    addModulator(colr.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        (int)((int)colr.getValuef() * smoothness.getValuef() / 100) * 100 / smoothness.getValuef(), 
        100, 
        100
      );
    }
  }
}

class OrderTest extends LXPattern {
  
  SawLFO sweep = new SawLFO(0, 15.999, 8000);
  int[] order = new int[] { 1, 2, 3, 4, 5, 6, 9, 8, 10, 11, 12, 13, 14, 16, 15, 7 };
  
  OrderTest(LX lx) {
    super(lx);
    addModulator(sweep.start());
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        240,
        100,
        cube.clusterPosition == order[floor(sweep.getValuef())] ? 100 : 0
      );
    }
  }
}

class Palette extends LXPattern {
  
  Palette(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        cube.index % 360,
        100,
        100
      );
    }
  }
}

class SolidColor extends LXPattern {
  // 235 = blue, 135 = green, 0 = red
  final BasicParameter hue = new BasicParameter("HUE", 135, 0, 360);
  
  SolidColor(LX lx) {
    super(lx);
    addParameter(hue);
  }
  
  public void run(double deltaMs) {
    setColors(lx.hsb(hue.getValuef(), 100, 100));
  }
}

class ClusterLineTest extends LXPattern {
  
  final BasicParameter y;
  final BasicParameter theta;
  final BasicParameter spin;
  
  ClusterLineTest(LX lx) {
    super(lx);
    
    addParameter(theta = new BasicParameter("θ", 0, -90, 430));
    addParameter(y = new BasicParameter("Y", 200, lx.model.yMin, lx.model.yMax));
    addParameter(spin = new BasicParameter("SPIN", 0, -90, 430));
  }
  
  public void run(double deltaMs) {
    PVector origin = new PVector(theta.getValuef(), y.getValuef());
    for (Cube cube : model.cubes) {
      PVector cubePointPrime = movePointToSamePlane(origin, cube.cylinderPoint);
      float dist = origin.dist(cubePointPrime);
      float cubeTheta = (spin.getValuef() + 15) + PVector.sub(cubePointPrime, origin).heading() * 180 / PI + 360;
      colors[cube.index] = lx.hsb(135, 100, 100
          * LXUtils.constrainf((1 - abs(cubeTheta % 90 - 15) / 100 / asin(20 / max(20, dist))), 0, 1));
    }
  }
}

class GhostEffect extends LXEffect {
  
  final BasicParameter amount = new BasicParameter("GHOS", 0, 0, 1, BasicParameter.Scaling.QUAD_IN);
  
  GhostEffect(LX lx) {
    super(lx);
    addLayer(new GhostEffectsLayer());
  }
  
  protected void apply(int[] colors) {
  }
  
  class GhostEffectsLayer extends LXLayer {
    
    GhostEffectsLayer() {
      addParameter(amount);
    }
  
    float timer = 0;
    ArrayList<GhostEffectLayer> ghosts = new ArrayList<GhostEffectLayer>();
    
    public void run(double deltaMs, int[] colors) {
      if (amount.getValue() != 0) {
        timer += deltaMs;
        float lifetime = (float)amount.getValue() * 2000;
        if (timer >= lifetime) {
          timer = 0;
          GhostEffectLayer ghost = new GhostEffectLayer();
          ghost.lifetime = lifetime * 3;
          addLayer(ghost);
          ghosts.add(ghost);
        }
      }
      if (ghosts.size() > 0) {
        Iterator<GhostEffectLayer> iter = ghosts.iterator();
        while (iter.hasNext()) {
          GhostEffectLayer ghost = iter.next();
          if (!ghost.running) {
            layers.remove(ghost);
            iter.remove();
          }
        }
      }
      
      for (LXModulator m : this.modulators) {
        m.run(deltaMs);
      }
      for (LXLayer layer : this.layers) {
        layer.run(deltaMs, colors);
      }
    }
    
    public void onParameterChanged(LXParameter parameter) {
      if (parameter.getValue() == 0) {
        timer = 0;
      }
    }
  }
  
  class GhostEffectLayer extends LXLayer {
    
    float lifetime;
    boolean running = true;
  
    private color[] ghostColors = null;
    float timer = 0;
    
    public void run(double deltaMs, int[] colors) {
      if (running) {
        timer += (float)deltaMs;
        if (timer >= lifetime) {
          running = false;
        } else {
          if (ghostColors == null) {
            ghostColors = new int[colors.length];
            for (int i = 0; i < colors.length; i++) {
              ghostColors[i] = colors[i];
            }
          }
          
          for (int i = 0; i < colors.length; i++) {
            ghostColors[i] = blendColor(ghostColors[i], lx.hsb(0, 0, 100 * max(0, (float)(1 - deltaMs / lifetime))), MULTIPLY);
            colors[i] = blendColor(colors[i], ghostColors[i], LIGHTEST);
          }
        }
      }
    }
  }
}


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

abstract class MultiObjectPattern <ObjectType extends MultiObject> extends LXPattern {
  
  BasicParameter frequency;
  
  ArrayList<ObjectType> objects;
  
  double pauseTimerCountdown = 0;
  
  MultiObjectPattern(LX lx) {
    super(lx);
    
    frequency = getFrequencyParameter();
    addParameter(frequency);
    
    objects = new ArrayList<ObjectType>();
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", 40, .1, 40, BasicParameter.Scaling.QUAD_IN);
  }
  
  public void run(double deltaMs) {
    
    if (objects.size() < ceil(frequency.getValuef())) {
      int missing = ceil(frequency.getValuef()) - objects.size();
      pauseTimerCountdown -= deltaMs;
      if (pauseTimerCountdown <= 0 || missing >= 5) {
        pauseTimerCountdown = (frequency.getValuef() < 1 ? 500 * (1 / frequency.getValuef() - 1) : 0)
                              + (missing == 1 ? random(200) : random(50));
        for (int i = ceil(missing / 3.); i > 0; i--) {
          ObjectType object = generateObject();
          object.init();
          objects.add(object);
        }
      }
    }
    
    Iterator<ObjectType> iter = objects.iterator();
    while (iter.hasNext()) {
      ObjectType object = iter.next();
      object.run(deltaMs);
      if (!object.running) {
        iter.remove();
      }
    }
    
    for (Cube cube : model.cubes) {
      blendColor(cube.index, lx.hsb(0, 0, 10), SUBTRACT);
      PVector cubePoint = new PVector(cube.theta, cube.y);
      for (ObjectType object : objects) {
        addColor(cube.index, object.getColorForCube(cubePoint));
      }
    }
  }
  
  abstract ObjectType generateObject();
}

abstract class MultiObject {
  boolean running = true;
  abstract public void run(double deltaMs);
  abstract int getColorForCube(PVector cubePoint);
  void init() { }
}

class Explosions extends MultiObjectPattern<Explosion> {
  
  ArrayList<Explosion> explosions;
  
  Explosions(LX lx) {
    super(lx);
    
    explosions = new ArrayList<Explosion>();
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", .50, .1, 40, BasicParameter.Scaling.QUAD_IN);
  }
  
  Explosion generateObject() {
    Explosion explosion = new Explosion();
    explosion.origin = new PVector(random(360), (float)LXUtils.random(model.yMin + 50, model.yMax - 50));
    explosion.hue = (int)random(360);
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
  
  void run(double deltaMs) {
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
          state = EXPLOSION_STATE_FLASH;
          lx.removeModulator(implosionRadius.stop());
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
  
  int getColorForCube(PVector cubePoint) {
    PVector cubePointPrime = movePointToSamePlane(origin, cubePoint);
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
  final BasicParameter thickness = new BasicParameter("WIDT", 1.5, 1, 20, BasicParameter.Scaling.QUAD_IN);
  final BasicParameter speed = new BasicParameter("SPEE", 60, 1, 100, BasicParameter.Scaling.QUAD_IN);

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
    
  Wisp generateObject() {
    Wisp wisp = new Wisp();
    wisp.runningTimer = 0;
    wisp.runningTimerEnd = 5000 / speed.getValuef();
    wisp.decayTime = wisp.runningTimerEnd;
    float pathDirection = (float)(direction.getValuef()
      + LXUtils.random(-directionVariability.getValuef(), directionVariability.getValuef())) % 360;
    wisp.pathDist = (float)LXUtils.random(80, min(450, 140 / max(0.01, abs(cos(PI * pathDirection / 180)))));
    wisp.startTheta = random(360);
    wisp.startY = (float)LXUtils.random(max(model.yMin, model.yMin - wisp.pathDist
      * sin(PI * pathDirection / 180)), 
    min(model.yMax, model.yMax - wisp.pathDist
      * sin(PI * pathDirection / 180)));
    wisp.startPoint = new PVector(wisp.startTheta, wisp.startY);
    wisp.endTheta = wisp.startTheta + wisp.pathDist * cos(PI * pathDirection / 180);
    wisp.endY = wisp.startY + wisp.pathDist * sin(PI * pathDirection / 180);
    wisp.displayColor = (int)(baseColor.getValuef()
      + LXUtils.random(-colorVariability.getValuef(), colorVariability.getValuef())) % 360;
    wisp.thickness = thickness.getValuef() + (float)LXUtils.random(-.3, .3);
    
    return wisp;
  }
}

class Wisp extends MultiObject {
  
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
  float globalFadeFactor;
  
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
        globalFadeFactor = max((runningTimer - runningTimerEnd) / decayTime, 0);
      }
    }
  }
  
  int getColorForCube(PVector cubePoint) {
    return lx.hsb(displayColor, 100, getBrightnessForCube(cubePoint));
  }
  
  float getBrightnessForCube(PVector cubePoint) {
//    float distFromSource = PVector.dist(cubePoint, currentPoint);
//    float tailFadeFactor = distFromSource / pathDist;
//    return max(0, (100 - 10 * distFromSource / thickness));
//    float dist = (float)LXUtils.distance(currentTheta, currentY,
//      closestPointToTrail.x, closestPointToTrail.y);
//    return max(0, (100 - 10 * distFromTrail / thickness) * max(0, 1 - tailFadeFactor - globalFadeFactor));
    PVector closestPointToTrail = getClosestPointOnLineOnCylinder(startPoint, currentPoint, cubePoint);
    float distFromSource = (float)LXUtils.distance(currentTheta, currentY,
      closestPointToTrail.x, closestPointToTrail.y);
    
    float distFromTrail = sqrt(pow(LXUtils.wrapdistf(closestPointToTrail.x, cubePoint.x, 360), 2)
                         + pow(closestPointToTrail.y - cubePoint.y, 2));
    float tailFadeFactor = distFromSource / pathDist;
    return max(0, (100 - 10 * distFromTrail / thickness) * max(0, 1 - tailFadeFactor - globalFadeFactor));
  }
}

//float wrapDist2d(PVector a, PVector b) {
//  
//}

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
   
  RainDrop generateObject() {
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
  
  int getColorForCube(PVector cubePoint) {
    float distFromSource = PVector.dist(cubePoint, currentPoint);
    float tailFadeFactor = distFromSource / pathDist;
    return lx.hsb(displayColor, 100, max(0, (100 - 10 * distFromSource / thickness)));
  }
}

class Strobe extends LXPattern {
  
  final BasicParameter speed = new BasicParameter("SPEE", 200, 3000, 30, BasicParameter.Scaling.QUAD_OUT);
  final BasicParameter balance = new BasicParameter("BAL", .5, .01, .99);

  int timer = 0;
  boolean on = false;
  
  Strobe(LX lx) {
    super(lx);
    
    addParameter(speed);
    addParameter(balance);
  }
  
  public void run(double deltaMs) {
    timer += deltaMs;
    if (timer >= speed.getValuef() * (on ? balance.getValuef() : 1 - balance.getValuef())) {
      timer = 0;
      on = !on;
    }
    
    setColors(on ? WHITE : BLACK);
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


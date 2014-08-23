int WHITE = java.awt.Color.WHITE.getRGB();
int BLACK = java.awt.Color.BLACK.getRGB();

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

float thetaDistance(float thetaA, float thetaB) {
  return LXUtils.wrapdistf(thetaA, thetaB, 360);
}

class BassSlam extends TSTriggerablePattern {
  
  final private double flashTimePercent = 0.1;
  final private int patternHue = 200;
  
  BassSlam(LX lx) {
    super(lx);

    patternMode = PATTERN_MODE_FIRED;
  }
  
  public void run(double deltaMs) {
    if (triggerableModeEnabled) {
      firedTimer += deltaMs / 800;
      if (firedTimer > 1) {
        getChannel().enabled.setValue(false);
        return;
      }
    }

    if (progress() < flashTimePercent) {
      setColors(lx.hsb(patternHue, 100, 100));
    } else {
      float time = (float)((progress() - flashTimePercent) / (1 - flashTimePercent) * 1.3755);
      float y;
      // y = 0 when time = 1.3755
      if (time < 1) {
        y = 1 + pow(time + 0.16, 2) * sin(18 * (time + 0.16)) / 4;
      } else {
        y = 1.32 - 20 * pow(time - 1, 2);
      }
      y = max(0, 100 * (y - 1) + 250);
      
      for (Cube cube : model.cubes) {
        setColor(cube.index, lx.hsb(patternHue, 100, LXUtils.constrainf(100 - 2 * abs(y - cube.transformedY), 0, 100)));
      }
    }
  }

  double progress() {
    return triggerableModeEnabled ? ((firedTimer + flashTimePercent) % 1) : lx.tempo.ramp();
  }
}

abstract class MultiObjectPattern <ObjectType extends MultiObject> extends TSTriggerablePattern {
  
  BasicParameter frequency;
  
  final boolean shouldAutofade;
  float fadeTime = 1000;
  
  final ArrayList<ObjectType> objects;
  double pauseTimerCountdown = 0;
//  BasicParameter fadeLength
  
  MultiObjectPattern(LX lx) {
    this(lx, true);
  }
  
  MultiObjectPattern(LX lx, double initial_frequency) {
    this(lx, true);
    frequency.setValue(initial_frequency);
  }

  MultiObjectPattern(LX lx, boolean shouldAutofade) {
    super(lx);

    patternMode = PATTERN_MODE_CUSTOM;
    
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
    if (triggered) {
      pauseTimerCountdown -= deltaMs;

      if (pauseTimerCountdown <= 0) {
        float delay = 1000 / frequency.getValuef();
        pauseTimerCountdown = random(delay / 2) + delay * 3 / 4;
        makeObject(0);
      }
    }
    
    if (shouldAutofade) {
      for (Cube cube : model.cubes) {
        blendColor(cube.index, lx.hsb(0, 0, 100 * max(0, (float)(1 - deltaMs / fadeTime))), LXColor.Blend.MULTIPLY);
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
  
  public void onTriggered(float strength) {
    super.onTriggered(strength);

    makeObject(strength);
  }
    
  abstract ObjectType generateObject(float strength);
}

abstract class MultiObject extends LXLayer {
  
  boolean firstRun = true;
  float runningTimer = 0;
  float runningTimerEnd = 1000;
  boolean running = true;
  float progress;
  int hue = BLACK;
  float thickness;
  boolean shouldFade = true;
  
  PVector lastPoint;
  PVector currentPoint;
  float fadeIn = 1;
  float fadeOut = 1;
  
  MultiObject(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    if (running) {
      if (firstRun) {
        advance(0);
        firstRun = false;
      } else {
        advance(deltaMs);
      }
      if (running) {
        for (Cube cube : model.cubes) {
          colors[cube.index] = blendColor(colors[cube.index], getColorForCube(cube), LIGHTEST);
        }
      }
    }
  }
  
  protected void advance(double deltaMs) {
    if (running) {
      runningTimer += deltaMs;
      if (runningTimer >= runningTimerEnd) {
        running = false;
      } else {
        progress = runningTimer / runningTimerEnd;
        if (shouldFade) {
          fadeIn = min(1, 3 * (1 - progress));
          fadeOut = min(1, 3 * progress);
        }
        if (currentPoint == null) {
        }
        lastPoint = currentPoint;
        onProgressChanged(progress);
      }
    }
  }
  
  public int getColorForCube(Cube cube) {
    return lx.hsb(hue, 100, getBrightnessForCube(cube));
  }
  
  public float getBrightnessForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(currentPoint, cube.transformedCylinderPoint);
    float dist = MAX_FLOAT;

    PVector localLastPoint = lastPoint;
    if (localLastPoint != null) {
      while (PVector.dist(localLastPoint, currentPoint) > 10) {
        PVector increment = PVector.sub(currentPoint, localLastPoint);
        increment.setMag(10);
        PVector point = PVector.add(localLastPoint, increment);

        if (isInsideBoundingBox(cube, cubePointPrime, point)) {
          dist = min(dist, getDistanceFromGeometry(cube, cubePointPrime, point));
        }
        localLastPoint = point;
      }
    }

    if (isInsideBoundingBox(cube, cubePointPrime, currentPoint)) {
      dist = min(dist, getDistanceFromGeometry(cube, cubePointPrime, currentPoint));
    }
    return 100 * min(max(1 - dist / thickness, 0), 1) * fadeIn * fadeOut;
  }

  public boolean isInsideBoundingBox(Cube cube, PVector cubePointPrime, PVector currentPoint) {
    return insideOfBoundingBox(currentPoint, cubePointPrime, thickness, thickness);
  }

  public float getDistanceFromGeometry(Cube cube, PVector cubePointPrime, PVector currentPoint) {
    return PVector.dist(cubePointPrime, currentPoint);
  }
  
  public void init() { }
  
  public void onProgressChanged(float progress) { }
}

class Explosions extends MultiObjectPattern<Explosion> {
  
  ArrayList<Explosion> explosions;
  
  Explosions(LX lx) {
    this(lx, 0.5);
  }
  
  Explosions(LX lx, double speed) {
    super(lx, false);
    
    explosions = new ArrayList<Explosion>();

    frequency.setValue(speed);
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", .50, .1, 20, BasicParameter.Scaling.QUAD_IN);
  }
  
  Explosion generateObject(float strength) {
    Explosion explosion = new Explosion(lx);
    explosion.origin = new PVector(random(360), (float)LXUtils.random(model.yMin + 50, model.yMax - 50));
    explosion.hue = (int) random(360);
    return explosion;
  }
}

class Explosion extends MultiObject {
  
  final static int EXPLOSION_STATE_IMPLOSION_EXPAND = 1 << 0;
  final static int EXPLOSION_STATE_IMPLOSION_WAIT = 1 << 1;
  final static int EXPLOSION_STATE_IMPLOSION_CONTRACT = 1 << 2;
  final static int EXPLOSION_STATE_EXPLOSION = 1 << 3;
  
  PVector origin;
  
  float accelOfImplosion = 3000;
  Accelerator implosionRadius;
  float implosionWaitTimer = 100;
  Accelerator explosionRadius;
  LXModulator explosionFade;
  float explosionThetaOffset;
  
  int state = EXPLOSION_STATE_IMPLOSION_EXPAND;
  
  Explosion(LX lx) {
    super(lx);
  }
  
  void init() {
    explosionThetaOffset = random(360);
    implosionRadius = new Accelerator(0, 700, -accelOfImplosion);
    addModulator(implosionRadius).start();
    explosionFade = new LinearEnvelope(1, 0, 1000);
  }
  
  protected void advance(double deltaMs) {
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
          removeModulator(implosionRadius).stop();
          state = EXPLOSION_STATE_EXPLOSION;
          explosionRadius = new Accelerator(0, -implosionRadius.getVelocityf(), -300);
          addModulator(explosionRadius).start();
          addModulator(explosionFade).start();
        }
        break;
      default:
        if (explosionFade.getValuef() <= 0) {
          running = false;
          removeModulator(explosionRadius).stop();
          removeModulator(explosionFade).stop();
        }
        break;
    }
  }
  
  public float getBrightnessForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(origin, cube.transformedCylinderPoint);
    float dist = origin.dist(cubePointPrime);
    switch (state) {
      case EXPLOSION_STATE_IMPLOSION_EXPAND:
      case EXPLOSION_STATE_IMPLOSION_WAIT:
      case EXPLOSION_STATE_IMPLOSION_CONTRACT:
        return 100 * LXUtils.constrainf((implosionRadius.getValuef() - dist) / 10, 0, 1);
      default:
        float theta = explosionThetaOffset + PVector.sub(cubePointPrime, origin).heading() * 180 / PI + 360;
        return 100
            * LXUtils.constrainf(1 - (dist - explosionRadius.getValuef()) / 10, 0, 1)
            * LXUtils.constrainf(1 - (explosionRadius.getValuef() - dist) / 200, 0, 1)
            * LXUtils.constrainf((1 - abs(theta % 30 - 15) / 100 / asin(20 / max(20, dist))), 0, 1)
            * explosionFade.getValuef();
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
    this(lx, .5, 210, 10, 90, 20, 3.5, 10);
  }

  Wisps(LX lx, double initial_frequency, double initial_color,
        double initial_colorVariability, double initial_direction,
        double initial_directionVariability, double initial_thickness,
        double initial_speed) {
    super(lx, initial_frequency);

    addParameter(baseColor);
    addParameter(colorVariability);
    addParameter(direction);
    addParameter(directionVariability);
    addParameter(thickness);
    addParameter(speed);

    baseColor.setValue(initial_color);
    colorVariability.setValue(initial_colorVariability);
    direction.setValue(initial_direction);
    directionVariability.setValue(initial_directionVariability);
    thickness.setValue(initial_thickness);
    speed.setValue(initial_speed);

  };

  Wisp generateObject(float strength) {
    Wisp wisp = new Wisp(lx);
    wisp.runningTimerEnd = 5000 / speed.getValuef();
    float pathDirection = (float)(direction.getValuef()
      + LXUtils.random(-directionVariability.getValuef(), directionVariability.getValuef())) % 360;
    float pathDist = (float)LXUtils.random(200, 400);
    float startTheta = random(360);
    float startY = (float)LXUtils.random(max(model.yMin, model.yMin - pathDist * sin(PI * pathDirection / 180)),
      min(model.yMax, model.yMax - pathDist * sin(PI * pathDirection / 180)));
    wisp.startPoint = new PVector(startTheta, startY);
    wisp.endPoint = PVector.fromAngle(pathDirection * PI / 180);
    wisp.endPoint.mult(pathDist);
    wisp.endPoint.add(wisp.startPoint);
    wisp.hue = (int)(baseColor.getValuef()
      + LXUtils.random(-colorVariability.getValuef(), colorVariability.getValuef())) % 360;
    wisp.thickness = 10 * thickness.getValuef() + (float)LXUtils.random(-3, 3);
    
    return wisp;
  }
}

class Wisp extends MultiObject {
  
  PVector startPoint;
  PVector endPoint;
  
  Wisp(LX lx) {
    super(lx);
  }
  
  public void onProgressChanged(float progress) {
    currentPoint = PVector.lerp(startPoint, endPoint, progress);
  }
}

class Rain extends MultiObjectPattern<RainDrop> {
  
  Rain(LX lx) {
    super(lx);
    fadeTime = 500;
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", 40, 1, 75);
  }
   
  RainDrop generateObject(float strength) {
    RainDrop rainDrop = new RainDrop(lx);

    rainDrop.runningTimerEnd = 180 + random(20);
    rainDrop.theta = random(360);
    rainDrop.startY = model.yMax + 20;
    rainDrop.endY = model.yMin - 20;
    rainDrop.hue = 200 + (int)random(20);
    rainDrop.thickness = 10 * (1.5 + random(.6));
    
    return rainDrop;
  }
}

class RainDrop extends MultiObject {
  
  float theta;
  float startY;
  float endY;
  
  RainDrop(LX lx) {
    super(lx);
    shouldFade = false;
  }
  
  public void onProgressChanged(float progress) {
    currentPoint = new PVector(theta, (float)LXUtils.lerp(startY, endY, progress));
  }
}

class Strobe extends TSTriggerablePattern {
  
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
    if (triggered) {
      timer += deltaMs;
      if (timer >= speed.getValuef() * (on ? balance.getValuef() : 1 - balance.getValuef())) {
        timer = 0;
        on = !on;
      }
      
      setColors(on ? WHITE : BLACK);
    }
  }
  
  public void onTriggered(float strength) {
    super.onTriggered(strength);

    on = true;
  }
  
  public void onRelease() {
    super.onRelease();

    timer = 0;
    on = false;
    setColors(BLACK);
  }
}

class StrobeOneshot extends TSTriggerablePattern {
  
  StrobeOneshot(LX lx) {
    super(lx);

    patternMode = PATTERN_MODE_FIRED;

    setColors(WHITE);
  }
  
  public void run(double deltaMs) {
    firedTimer += deltaMs;
    if (firedTimer >= 80) {
      getChannel().enabled.setValue(false);
    }
  }
}

class Brightness extends TSTriggerablePattern {
  
  Brightness(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
  }
  
  public void onTriggered(float strength) {
    setColors(lx.hsb(0, 0, 100 * strength));
  }
  
  public void onRelease() {
    setColors(BLACK);
  }
}

class RandomColor extends TSPattern {
  
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

class ColorStrobe extends TSTriggerablePattern {
  
  ColorStrobe(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    setColors(lx.hsb(random(360), 100, 100));
  }
}

class RandomColorGlitch extends TSPattern {
  
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

class Fade extends TSPattern {
  
  final BasicParameter speed = new BasicParameter("SPEE", 11000, 100000, 1000, BasicParameter.Scaling.QUAD_OUT);
  final BasicParameter smoothness = new BasicParameter("SMOO", 100, 1, 100, BasicParameter.Scaling.QUAD_IN);

  final SinLFO colr = new SinLFO(0, 360, speed);

  Fade(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(smoothness);
    addModulator(colr).start();
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

class OrderTest extends TSPattern {
  
  SawLFO sweep = new SawLFO(0, 15.999, 8000);
  int[] order = new int[] { 1, 2, 3, 4, 5, 6, 9, 8, 10, 11, 12, 13, 14, 16, 15, 7 };
  
  OrderTest(LX lx) {
    super(lx);
    addModulator(sweep).start();
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

class Palette extends TSPattern {
  
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

class SolidColor extends TSPattern {
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

class ClusterLineTest extends TSPattern {
  
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
      PVector cubePointPrime = movePointToSamePlane(origin, cube.transformedCylinderPoint);
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
    addLayer(new GhostEffectsLayer(lx));
  }
  
  protected void run(double deltaMs) {
  }
  
  class GhostEffectsLayer extends LXLayer {
    
    GhostEffectsLayer(LX lx) {
      super(lx);
      addParameter(amount);
    }
  
    float timer = 0;
    ArrayList<GhostEffectLayer> ghosts = new ArrayList<GhostEffectLayer>();
    
    public void run(double deltaMs) {
      if (amount.getValue() != 0) {
        timer += deltaMs;
        float lifetime = (float)amount.getValue() * 2000;
        if (timer >= lifetime) {
          timer = 0;
          GhostEffectLayer ghost = new GhostEffectLayer(lx);
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
    }
    
    public void onParameterChanged(LXParameter parameter) {
      if (parameter == amount && parameter.getValue() == 0) {
        timer = 0;
      }
    }
  }
  
  class GhostEffectLayer extends LXLayer {
    
    float lifetime;
    boolean running = true;
  
    private color[] ghostColors = null;
    float timer = 0;
    
    GhostEffectLayer(LX lx) {
      super(lx);
    }
    
    public void run(double deltaMs) {
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

class ScrambleEffect extends LXEffect {
  
  final DiscreteParameter amount;
  final int offset;
  
  ScrambleEffect(LX lx) {
    super(lx);
    
    amount = new DiscreteParameter("SCRA", lx.total / 2);
    offset = lx.total / 4 + 5;
  }
  
  protected void run(double deltaMs) {
    for (Tree tree : model.trees) {
      for (int i = min(tree.cubes.size(), amount.getValuei()); i > 0; i--) {
        colors[tree.cubes.get(i).index] = colors[tree.cubes.get((i + offset) % tree.cubes.size()).index];
      }
    }
  }
}

class StaticEffect extends LXEffect {
  
  final BasicParameter amount = new BasicParameter("STTC");
  
  private boolean isCreatingStatic = false;
  
  StaticEffect(LX lx) {
    super(lx);
  }
  
  protected void run(double deltaMs) {
    if (amount.getValue() > 0) {
      if (isCreatingStatic) {
        double chance = random(1);
        if (chance > amount.getValue()) {
          isCreatingStatic = false;
        }
      } else {
        double chance = random(1);
        if (chance < amount.getValue()) {
          isCreatingStatic = true;
        }
      }
      if (isCreatingStatic) {
        for (int i = 0; i < colors.length; i++) {
          colors[i] = color(random(255));
        }
      }
    }
  }
}

class SpeedEffect extends LXEffect {

  final BasicParameter speed = new BasicParameter("SPEED", 1, .1, 10, BasicParameter.Scaling.QUAD_IN);

  SpeedEffect(final LX lx) {
    super(lx);

    speed.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        lx.engine.setSpeed(speed.getValue());
      }
    });
  }

  void run(double deltaMs) {}
}

class RotationEffect extends ModelTransform {
  
  final BasicParameter rotation = new BasicParameter("ROT", 0, 0, 360);

  RotationEffect(LX lx) {
    super(lx);
  }

  void transform(Model model) {
    if (rotation.getValue() > 0) {
      float rotationTheta = rotation.getValuef();
      for (Cube cube : model.cubes) {
        cube.transformedTheta = (cube.transformedTheta + 360 - rotationTheta) % 360;
      }
    }
  }
}

class SpinEffect extends ModelTransform {
  
  final BasicParameter spin = new BasicParameter("SPIN");
  final FunctionalParameter rotationPeriodMs = new FunctionalParameter() {
    public double getValue() {
      return 5000 - 4800 * spin.getValue();
    }
  };
  final SawLFO rotation = new SawLFO(0, 360, rotationPeriodMs);

  SpinEffect(LX lx) {
    super(lx);

    addModulator(rotation);

    spin.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        if (spin.getValue() > 0) {
          rotation.start();
          rotation.setLooping(true);
        } else {
          rotation.setLooping(false);
        }
      }
    });
  }

  void transform(Model model) {
    if (rotation.getValue() > 0 && rotation.getValue() < 360) {
      float rotationTheta = rotation.getValuef();
      for (Cube cube : model.cubes) {
        cube.transformedTheta = (cube.transformedTheta + 360 - rotationTheta) % 360;
      }
    }
  }
}

class ColorStrobeTextureEffect extends LXEffect {

  final BasicParameter amount = new BasicParameter("SEIZ", 0, 0, 1, BasicParameter.Scaling.QUAD_IN);

  ColorStrobeTextureEffect(LX lx) {
    super(lx);
  }

  void run(double deltaMs) {
    if (amount.getValue() > 0) {
      float newHue = random(360);
      int newColor = lx.hsb(newHue, 100, 100);
      for (int i = 0; i < colors.length; i++) {
        int oldColor = colors[i];
        int blendedColor = lerpColor(oldColor, newColor, amount.getValuef());
        colors[i] = lx.hsb(LXColor.h(blendedColor), LXColor.s(blendedColor), LXColor.b(oldColor));
      }
    }
  }
}

class FadeTextureEffect extends LXEffect {

  final BasicParameter amount = new BasicParameter("FADE");

  final SawLFO colr = new SawLFO(0, 360, 10000);

  FadeTextureEffect(LX lx) {
    super(lx);

    addModulator(colr).start();
  }

  void run(double deltaMs) {
    if (amount.getValue() > 0) {
      float newHue = colr.getValuef();
      int newColor = lx.hsb(newHue, 100, 100);
      for (int i = 0; i < colors.length; i++) {
        int oldColor = colors[i];
        int blendedColor = lerpColor(oldColor, newColor, amount.getValuef());
        colors[i] = lx.hsb(LXColor.h(blendedColor), LXColor.s(blendedColor), LXColor.b(oldColor));
      }
    }
  }
}

class AcidTripTextureEffect extends LXEffect {

  final BasicParameter amount = new BasicParameter("ACID");
  
  final SawLFO trails = new SawLFO(360, 0, 7000);

  AcidTripTextureEffect(LX lx) {
    super(lx);
    
    addModulator(trails).start();
  }

  void run(double deltaMs) {
    if (amount.getValue() > 0) {
      for (int i = 0; i < colors.length; i++) {
        int oldColor = colors[i];
        Cube cube = model.cubes.get(i);
        float newHue = abs(model.cy - cube.transformedY) + abs(model.cy - cube.transformedTheta) + trails.getValuef() % 360;
        int newColor = lx.hsb(newHue, 100, 100);
        int blendedColor = lerpColor(oldColor, newColor, amount.getValuef());
        colors[i] = lx.hsb(LXColor.h(blendedColor), LXColor.s(blendedColor), LXColor.b(oldColor));
      }
    }
  }
}

class CandyTextureEffect extends LXEffect {

  final BasicParameter amount = new BasicParameter("CAND");

  double time = 0;

  CandyTextureEffect(LX lx) {
    super(lx);
  }

  void run(double deltaMs) {
    if (amount.getValue() > 0) {
      time += deltaMs;
      for (int i = 0; i < colors.length; i++) {
        int oldColor = colors[i];
        float newHue = i * 127 + 9342 + (float)time % 360;
        int newColor = lx.hsb(newHue, 100, 100);
        int blendedColor = lerpColor(oldColor, newColor, amount.getValuef());
        colors[i] = lx.hsb(LXColor.h(blendedColor), LXColor.s(blendedColor), LXColor.b(oldColor));
      }
    }
  }
}

class CandyCloudTextureEffect extends LXEffect {

  final BasicParameter amount = new BasicParameter("CLOU");

  double time = 0;
  final double scale = 2400;
  final double speed = 1.0 / 5000;

  CandyCloudTextureEffect(LX lx) {
    super(lx);
  }

  void run(double deltaMs) {
    if (amount.getValue() > 0) {
      time += deltaMs;
      for (int i = 0; i < colors.length; i++) {
        int oldColor = colors[i];
        Cube cube = model.cubes.get(i);

        double adjustedX = cube.x / scale;
        double adjustedY = cube.y / scale;
        double adjustedZ = cube.z / scale;
        double adjustedTime = time * speed;

        float newHue = ((float)SimplexNoise.noise(adjustedX, adjustedY, adjustedZ, adjustedTime) + 1) / 2 * 1080 % 360;
        int newColor = lx.hsb(newHue, 100, 100);

        int blendedColor = lerpColor(oldColor, newColor, amount.getValuef());
        colors[i] = lx.hsb(LXColor.h(blendedColor), LXColor.s(blendedColor), LXColor.b(oldColor));
      }
    }
  }
}

class CandyCloud extends TSPattern {

  final BasicParameter darkness = new BasicParameter("DARK", 8, 0, 12);

  final BasicParameter scale = new BasicParameter("SCAL", 2400, 600, 10000);
  final BasicParameter speed = new BasicParameter("SPD", 1, 1, 2);

  double time = 0;

  CandyCloud(LX lx) {
    super(lx);

    addParameter(darkness);
  }

  void run(double deltaMs) {
    time += deltaMs;
    for (Cube cube : model.cubes) {
      double adjustedX = cube.x / scale.getValue();
      double adjustedY = cube.y / scale.getValue();
      double adjustedZ = cube.z / scale.getValue();
      double adjustedTime = time * speed.getValue() / 5000;

      float hue = ((float)SimplexNoise.noise(adjustedX, adjustedY, adjustedZ, adjustedTime) + 1) / 2 * 1080 % 360;

      float brightness = min(max((float)SimplexNoise.noise(cube.x / 250, cube.y / 250, cube.z / 250 + 10000, time / 5000) * 8 + 8 - darkness.getValuef(), 0), 1) * 100;
      
      colors[cube.index] = lx.hsb(hue, 100, brightness);
    }
  }
}

class GalaxyCloud extends TSPattern {

  double time = 0;

  GalaxyCloud(LX lx) {
    super(lx);
  }

  void run(double deltaMs) {
    // Blue to purple
    float hueMin = 240;
    float hueMax = 280;
    float hueMinExtra = 80;
    float hueMaxExtra = 55;

    float hueSpread = hueMax - hueMin;
    float hueMid = hueSpread / 2 + hueMin;
    float initialSpreadSize = hueMinExtra + hueMaxExtra;
    float initialSpreadMin = hueMid - hueMinExtra;

    time += deltaMs;
    for (Cube cube : model.cubes) {
      float adjustedTheta = cube.transformedTheta / 360;
      float adjustedY = (cube.transformedY - model.yMin) / (model.yMax - model.yMin);
      float adjustedTime = (float)time / 5000;

      // Use 2 textures so we don't have a seam. Interpolate between them between -45 & 45 and 135 & 225
      float hue1 = noise(4 * adjustedTheta, 4 * adjustedY, adjustedTime);
      float hue2 = noise(4 * ((adjustedTheta + 0.5) % 1), 4 * adjustedY + 100, adjustedTime);
      float hue = lerp(hue1, hue2, min(max(abs(((adjustedTheta * 4 + 1) % 4) - 2) - 0.5, 0), 1));

      float adjustedHue = hue * initialSpreadSize + initialSpreadMin;
      hue = min(max(adjustedHue, hueMin), hueMax);

      // make it black if the hue would go below hueMin or above hueMax
      // normalizedFadeOut: 0 = edge of the initial spread, 1 = edge of the hue spread, >1 = in the hue spread
      float normalizedFadeOut = (adjustedHue - hueMid + hueMinExtra) / (hueMinExtra - hueSpread / 2);
      // scaledFadeOut <0 = black sooner, 0-1 = fade out gradient, >1 = regular color
      float scaledFadeOut = normalizedFadeOut * 5 - 4.5;
      float brightness = min(max(scaledFadeOut, 0), 1) * 100;

      // float brightness = min(max((float)SimplexNoise.noise(4 * adjustedX, 4 * adjustedY, 4 * adjustedZ + 10000, adjustedTime) * 8 - 1, 0), 1) * 100;

      colors[cube.index] = lx.hsb(hue, 100, brightness);
    }
  }
}

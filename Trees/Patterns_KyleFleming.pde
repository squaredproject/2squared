int WHITE = java.awt.Color.WHITE.getRGB();
int BLACK = java.awt.Color.BLACK.getRGB();

class BassSlam extends LXPattern {
  
  final private double flashTimePercent = 0.1;
  final private int patternHue = 200;
  
  BassSlam(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    if (lx.tempo.ramp() < flashTimePercent) {
      setColors(lx.hsb(patternHue, 100, 100));
    } else {
      float time = (float)((lx.tempo.ramp() - flashTimePercent) / (1 - flashTimePercent) * 1.3755);
      float y;
      // y = 0 when time = 1.3755
      if (time < 1) {
        y = 1 + pow(time + 0.16, 2) * sin(18 * (time + 0.16)) / 4;
      } else {
        y = 1.32 - 20 * pow(time - 1, 2);
      }
      y = max(0, 100 * (y - 1) + 250);
      
      for (Cube cube : model.cubes) {
        setColor(cube.index, lx.hsb(patternHue, 100, LXUtils.constrainf(100 - 2 * abs(y - cube.y), 0, 100)));
      }
    }
  }
}

abstract class MultiObjectPattern <ObjectType extends MultiObject> extends LXPattern implements Triggerable, KeyboardPlayablePattern {
  
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
    if (getChannel().getFader().getNormalized() == 0) return;

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
  
  float runningTimer = 0;
  float runningTimerEnd = 1000;
  boolean running = true;
  float progress;
  int hue = BLACK;
  float thickness;
  
  PVector currentPoint;
  float fadeIn;
  float fadeOut;
  
  MultiObject(LX lx) {
    super(lx);
  }
  
  public void run(double deltaMs) {
    if (running) {
      advance(deltaMs);
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
        fadeIn = min(1, 3 * (1 - progress));
        fadeOut = min(1, 3 * progress);
        onProgressChanged(progress);
      }
    }
  }
  
  public int getColorForCube(Cube cube) {
    return lx.hsb(hue, 100, getBrightnessForCube(cube));
  }
  
  public float getBrightnessForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(currentPoint, cube.cylinderPoint);
    if (insideOfBoundingBox(currentPoint, cubePointPrime, thickness, thickness)) {
      float dist = PVector.dist(cubePointPrime, currentPoint);
      return 100 * max(0, (1 - dist / thickness)) * fadeIn * fadeOut;
    } else {
      return 0;
    }
  }
  
  float getRunningTimeEstimate() {
    return runningTimerEnd;
  }
  
  public void init() { }
  public void onProgressChanged(float progress) { }
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
    Explosion explosion = new Explosion(lx);
    explosion.origin = new PVector(random(360), (float)LXUtils.random(model.yMin + 50, model.yMax - 50));
    explosion.hue = (int)(keyboardMode ? (360 * modWheelValue) : random(360));
    return explosion;
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
    lx.addModulator(implosionRadius.start());
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
          lx.removeModulator(implosionRadius.stop());
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
  
  public float getBrightnessForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(origin, cube.cylinderPoint);
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
    super(lx);
    
    addParameter(baseColor);
    addParameter(colorVariability);
    addParameter(direction);
    addParameter(directionVariability);
    addParameter(thickness);
    addParameter(speed);
  }
    
  Wisp generateObject(float strength) {
    Wisp wisp = new Wisp(lx);
    wisp.runningTimer = 0;
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
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", 40, .1, 75, BasicParameter.Scaling.QUAD_IN);
  }
   
  RainDrop generateObject(float strength) {
    RainDrop rainDrop = new RainDrop(lx);
    rainDrop.runningTimerEnd = 180 + random(20);
    rainDrop.decayTime = rainDrop.runningTimerEnd;
    rainDrop.theta = random(360);
    rainDrop.startY = model.yMax + 20;
    rainDrop.endY = model.yMin - 20;
    rainDrop.pathDist = abs(rainDrop.endY - rainDrop.startY);
    rainDrop.hue = 200 + (int)random(20);
    rainDrop.thickness = 1.5 + random(.6);
    
    return rainDrop;
  }
}

class RainDrop extends MultiObject {
  
  float decayTime;
  
  float theta;
  float startY;
  float endY;
  float pathDist;
  
  RainDrop(LX lx) {
    super(lx);
  }
  
  protected void advance(double deltaMs) {
    if (running) {
      runningTimer += deltaMs;
      if (runningTimer >= runningTimerEnd + decayTime) {
        running = false;
      } else {
        float percentDone = min(runningTimer, runningTimerEnd) / runningTimerEnd;
        currentPoint = new PVector(theta, (float)LXUtils.lerp(startY, endY, percentDone));
      }
    }
  }
  
  public float getBrightnessForCube(Cube cube) {
    PVector cubePointPrime = movePointToSamePlane(currentPoint, cube.cylinderPoint);
    float distFromSource = PVector.dist(cubePointPrime, currentPoint);
    float tailFadeFactor = distFromSource / pathDist;
    return max(0, (100 - 10 * distFromSource / thickness));
  }
}

class Strobe extends LXPattern implements Triggerable {
  
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
    if (getChannel().getFader().getNormalized() == 0) return;

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

class Brightness extends LXPattern implements Triggerable {
  
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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;

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
    if (getChannel().getFader().getNormalized() == 0) return;
    
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
    for (Tree tree : ((Model)lx.model).trees) {
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



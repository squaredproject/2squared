import java.util.ArrayList;

import heronarts.lx.LX;
import heronarts.lx.LXUtils;
import heronarts.lx.modulator.SawLFO;
import heronarts.lx.modulator.SinLFO;
import heronarts.lx.parameter.BasicParameter;
import heronarts.lx.parameter.BooleanParameter;
import heronarts.lx.parameter.DiscreteParameter;

import org.apache.commons.lang3.ArrayUtils;

import toxi.math.MathUtils;

class SparkleHelix extends TSPattern {
  final BasicParameter minCoil = new BasicParameter("MinCOIL", .02, .005, .05);
  final BasicParameter maxCoil = new BasicParameter("MaxCOIL", .03, .005, .05);
  final BasicParameter sparkle = new BasicParameter("Spark", 80, 160, 10);
  final BasicParameter sparkleSaturation = new BasicParameter("Sat", 50, 0, 100);
  final BasicParameter counterSpiralStrength = new BasicParameter("Double", 0, 0, 1);
  
  final SinLFO coil = new SinLFO(minCoil, maxCoil, 8000);
  final SinLFO rate = new SinLFO(6000, 1000, 19000);
  final SawLFO spin = new SawLFO(0, MathUtils.TWO_PI, rate);
  final SinLFO width = new SinLFO(10, 20, 11000);
  long[] sparkleTimeOuts;
  SparkleHelix(LX lx) {
    super(lx);
    addParameter(minCoil);
    addParameter(maxCoil);
    addParameter(sparkle);
    addParameter(sparkleSaturation);
    addParameter(counterSpiralStrength);
    addModulator(rate).start();
    addModulator(coil).start();    
    addModulator(spin).start();
    addModulator(width).start();
    sparkleTimeOuts = new long[model.cubes.size()];
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      float compensatedWidth = (0.7f + .02f / coil.getValuef()) * width.getValuef();
      float spiralVal = Math.max(0, 100 - (100*MathUtils.TWO_PI / (compensatedWidth))*LXUtils.wrapdistf((MathUtils.TWO_PI / 360) * cube.transformedTheta, 8*MathUtils.TWO_PI + spin.getValuef() + coil.getValuef()*(cube.transformedY-model.cy), MathUtils.TWO_PI));
      float counterSpiralVal = counterSpiralStrength.getValuef() * Math.max(0, 100 - (100*MathUtils.TWO_PI / (compensatedWidth))*LXUtils.wrapdistf((MathUtils.TWO_PI / 360) * cube.transformedTheta, 8*MathUtils.TWO_PI - spin.getValuef() - coil.getValuef()*(cube.transformedY-model.cy), MathUtils.TWO_PI));
      float hueVal = (lx.getBaseHuef() + .1f*cube.transformedY) % 360;
      if (sparkleTimeOuts[cube.index] > System.currentTimeMillis()){        
        colors[cube.index] = lx.hsb(hueVal, sparkleSaturation.getValuef(), 100);
      }
      else{
        colors[cube.index] = lx.hsb(hueVal, 100, Math.max(spiralVal, counterSpiralVal));        
        if (MathUtils.random(Math.max(spiralVal, counterSpiralVal)) > sparkle.getValuef()){
          sparkleTimeOuts[cube.index] = System.currentTimeMillis() + 100;
        }
      }
    }
  }
}






class MultiSine extends TSPattern {
  final int numLayers = 3;
  int[][] distLayerDivisors = {{50, 140, 200}, {360, 60, 45}}; 
  final BasicParameter brightEffect = new BasicParameter("Bright", 100, 0, 100);

  final BasicParameter[] timingSettings =  {
    new BasicParameter("T1", 6300, 5000, 30000),
    new BasicParameter("T2", 4300, 2000, 10000),
    new BasicParameter("T3", 11000, 10000, 20000)
  };
  SinLFO[] frequencies = {
    new SinLFO(0, 1, timingSettings[0]),
    new SinLFO(0, 1, timingSettings[1]),
    new SinLFO(0, 1, timingSettings[2])
  };      
  MultiSine(LX lx) {
    super(lx);
    for (int i = 0; i < numLayers; i++){
      addParameter(timingSettings[i]);
      addModulator(frequencies[i]).start();
    }
    addParameter(brightEffect);
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {
      float[] combinedDistanceSines = {0, 0};
      for (int i = 0; i < numLayers; i++){
        combinedDistanceSines[0] += MathUtils.sin(MathUtils.TWO_PI * frequencies[i].getValuef() + cube.transformedY / distLayerDivisors[0][i]) / numLayers;
        combinedDistanceSines[1] += MathUtils.sin(MathUtils.TWO_PI * frequencies[i].getValuef() + MathUtils.TWO_PI*(cube.transformedTheta / distLayerDivisors[1][i])) / numLayers;
      }
      float hueVal = (lx.getBaseHuef() + 20 * MathUtils.sin(MathUtils.TWO_PI * (combinedDistanceSines[0] + combinedDistanceSines[1]))) % 360;
      float brightVal = (100 - brightEffect.getValuef()) + brightEffect.getValuef() * (2 + combinedDistanceSines[0] + combinedDistanceSines[1]) / 4;
      float satVal = 90 + 10 * MathUtils.sin(MathUtils.TWO_PI * (combinedDistanceSines[0] + combinedDistanceSines[1]));
      colors[cube.index] = lx.hsb(hueVal,  satVal, brightVal);
    }
  }
}



class Stripes extends TSPattern {
  final BasicParameter minSpacing = new BasicParameter("MinSpacing", 0.5, .3, 2.5);
  final BasicParameter maxSpacing = new BasicParameter("MaxSpacing", 2, .3, 2.5);
  final SinLFO spacing = new SinLFO(minSpacing, maxSpacing, 8000);
  final SinLFO slopeFactor = new SinLFO(0.05, 0.2, 19000);

  Stripes(LX lx) {
    super(lx);
    addParameter(minSpacing);
    addParameter(maxSpacing);
    addModulator(slopeFactor).start();
    addModulator(spacing).start();    
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    for (Cube cube : model.cubes) {  
      float hueVal = (lx.getBaseHuef() + .1f*cube.transformedY) % 360;
      float brightVal = 50 + 50 * MathUtils.sin(spacing.getValuef() * (MathUtils.sin((MathUtils.TWO_PI / 360) * 4 * cube.transformedTheta) + slopeFactor.getValuef() * cube.transformedY)); 
      colors[cube.index] = lx.hsb(hueVal,  100, brightVal);
    }
  }
}

class Ripple extends TSPattern {
  final BasicParameter speed = new BasicParameter("Speed", 15000, 25000, 8000);
  final BasicParameter baseBrightness = new BasicParameter("Bright", 0, 0, 100);
  final SawLFO rippleAge = new SawLFO(0, 100, speed);
  float hueVal;
  float brightVal;
  boolean resetDone = false;
  float yCenter;
  float thetaCenter;
  Ripple(LX lx) {
    super(lx);
    addParameter(speed);
    addParameter(baseBrightness);
    addModulator(rippleAge).start();    
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    if (rippleAge.getValuef() < 5){
      if (!resetDone){
        yCenter = 150 + MathUtils.random(300);
        thetaCenter = MathUtils.random(360);
        resetDone = true;
      }
    }
    else {
      resetDone = false;
    }
    float radius = (float)Math.pow(rippleAge.getValuef(), 2) / 3;
    for (Cube cube : model.cubes) {
      float distVal = (float)Math.sqrt((float)Math.pow((LXUtils.wrapdistf(thetaCenter, cube.transformedTheta, 360)) * 0.8, 2) + (float)Math.pow(yCenter - cube.transformedY, 2));
      float heightHueVariance = 0.1f * cube.transformedY;
      if (distVal < radius){
        float rippleDecayFactor = (100 - rippleAge.getValuef()) / 100;
        float timeDistanceCombination = distVal / 20 - rippleAge.getValuef();
        hueVal = (lx.getBaseHuef() + 40 * MathUtils.sin(MathUtils.TWO_PI * (12.5f + rippleAge.getValuef() )/ 200) * rippleDecayFactor * MathUtils.sin(timeDistanceCombination) + heightHueVariance + 360) % 360;
        brightVal = LXUtils.constrainf((baseBrightness.getValuef() + rippleDecayFactor * (100 - baseBrightness.getValuef()) + 80 * rippleDecayFactor * MathUtils.sin(timeDistanceCombination + MathUtils.TWO_PI / 8)), 0, 100);
      }
      else {
        hueVal = (lx.getBaseHuef() + heightHueVariance) % 360;
        brightVal = baseBrightness.getValuef(); 
      }
      colors[cube.index] = lx.hsb(hueVal,  100, brightVal);
    }
  }
}


class SparkleTakeOver extends TSPattern {
  long[] sparkleTimeOuts;
  int lastComplimentaryToggle = 0;
  int complimentaryToggle = 0;
  boolean resetDone = false;
  final SinLFO timing = new SinLFO(6000, 10000, 20000);
  final SawLFO coverage = new SawLFO(0, 100, timing);
  final BasicParameter hueVariation = new BasicParameter("HueVar", 0.1, 0.1, 0.4);
  float hueSeparation = 180;
  float newHueVal;
  float oldHueVal;
  float newBrightVal = 100;
  float oldBrightVal = 100;
  SparkleTakeOver(LX lx) {
    super(lx);
    sparkleTimeOuts = new long[model.cubes.size()];
    addModulator(timing).start();    
    addModulator(coverage).start();
    addParameter(hueVariation);
  }  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
    
    if (coverage.getValuef() < 5){
      if (!resetDone){
        lastComplimentaryToggle = complimentaryToggle;
        oldBrightVal = newBrightVal;
        if (MathUtils.random(5) < 2){          
          complimentaryToggle = 1 - complimentaryToggle;
          newBrightVal = 100;
        }
        else {
          newBrightVal = (newBrightVal == 100) ? 70 : 100;          
        }
        for (int i = 0; i < model.cubes.size(); i++){
          sparkleTimeOuts[i] = 0;
        }        
        resetDone = true;
      }
    }     
    else {
      resetDone = false;
    }
    for (Cube cube : model.cubes) {  
      float newHueVal = (lx.getBaseHuef() + complimentaryToggle * hueSeparation + hueVariation.getValuef() * cube.transformedY) % 360;
      float oldHueVal = (lx.getBaseHuef() + lastComplimentaryToggle * hueSeparation + hueVariation.getValuef() * cube.transformedY) % 360;
      if (sparkleTimeOuts[cube.index] > System.currentTimeMillis()){        
        colors[cube.index] = lx.hsb(newHueVal,  (30 + coverage.getValuef()) / 1.3f, newBrightVal);
      }
      else {
        colors[cube.index] = lx.hsb(oldHueVal,  (140 - coverage.getValuef()) / 1.4f, oldBrightVal);
        float chance = MathUtils.random(Math.abs(MathUtils.sin((MathUtils.TWO_PI / 360) * cube.transformedTheta * 4) * 50) + Math.abs(MathUtils.sin(MathUtils.TWO_PI * (cube.transformedY / 9000))) * 50);
        if (chance > (100 - 100*((float)Math.pow(coverage.getValuef()/100, 2)))){
          sparkleTimeOuts[cube.index] = System.currentTimeMillis() + 50000;
        }
        else if (chance > 1.1 * (100 - coverage.getValuef())){
          sparkleTimeOuts[cube.index] = System.currentTimeMillis() + 100;
        }
          
      }
        
    }
  }
}

class Lightning extends TSTriggerablePattern {
  private LightningLine[] bolts = new LightningLine[2];
  final BasicParameter boltAngle = new BasicParameter("Angle", 35, 0, 55);
  final BasicParameter propagationSpeed = new BasicParameter("Speed", 10, 0.5, 20);
  final BasicParameter maxBoltWidth = new BasicParameter("Width", 60, 20, 150);
  final BasicParameter lightningChance = new BasicParameter("Chance", 5, 1, 10);
  final BasicParameter forkingChance = new BasicParameter("Fork", 3, 1, 10);
  final BooleanParameter firesOnBeat = new BooleanParameter("Beat");
  long[] randomCheckTimeOuts = {0, 0};

  Lightning(LX lx) {
    super(lx);

    patternMode = PATTERN_MODE_FIRED;

    bolts[0] = makeBolt();
    bolts[1] = makeBolt();
    addParameter(boltAngle);
    addParameter(propagationSpeed);
    addParameter(maxBoltWidth);
    addParameter(lightningChance);
    addParameter(forkingChance);
    addParameter(firesOnBeat);
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;

    int treeIndex = 0;
    
    for (Tree tree : model.trees){
      if (bolts[treeIndex].isDead()) {
        if (triggered) {
          if (firesOnBeat.isOn()) {
            if (lx.tempo.beat()) {
              randomCheckTimeOuts[treeIndex] = System.currentTimeMillis() + 100;
              bolts[treeIndex] = makeBolt();
            }
          } else {
            if (randomCheckTimeOuts[treeIndex] < System.currentTimeMillis()){
              randomCheckTimeOuts[treeIndex] = System.currentTimeMillis() + 100;
              if (MathUtils.random(15) < lightningChance.getValuef()){
                bolts[treeIndex] = makeBolt();
              }
            }
          }
        } else {
          getChannel().enabled.setValue(false);
        }
      }
      for (Cube cube : tree.cubes) {
        float hueVal = 300;
        float lightningFactor = bolts[treeIndex].getLightningFactor(cube.transformedY, cube.transformedTheta);
        float brightVal = lightningFactor;
        float satVal;
        if (lightningFactor < 20){
          hueVal = 300;
          satVal = 100;
        }
        else if (lightningFactor < 50){
          hueVal = 280;
          satVal = 100;
        }
        else {
          hueVal = 280;
          satVal = 100 - 2 * (lightningFactor - 50);
        }
        colors[cube.index] = lx.hsb(hueVal,  satVal, brightVal);
      }
      treeIndex ++;
    }
  }
  LightningLine makeBolt(){
    float theta = 45 * (int) MathUtils.random(8);
    float boltWidth = (maxBoltWidth.getValuef() + MathUtils.random(maxBoltWidth.getValuef())) / 2;
    return new LightningLine (System.currentTimeMillis(), 550, theta, boltAngle.getValuef(), propagationSpeed.getValuef(), boltWidth, 3, forkingChance.getValuef());
  }
  
  public void onTriggered(float strength) {
    super.onTriggered(strength);

    propagationSpeed.setNormalized(strength);
    
    int treeIndex = 0;
    
    for (Tree tree : model.trees){
      if (bolts[treeIndex].isDead()){
        randomCheckTimeOuts[treeIndex] = System.currentTimeMillis() + 100;
        bolts[treeIndex] = makeBolt();
      }
      treeIndex ++;
    }
  }
}



class LightningLine {
  private final float treeBottomY = 100;
  private float[] yKeyPoints = {};
  private float[] thetaKeyPoints = {};
  private int lifeCycleState = 0;
  private final long startTime;
  private final float startY;
  private final float propagationSpeed;
  private final float lineWidth;
  private float wideningStartTime = 0;
  private ArrayList<LightningLine> forks = new ArrayList();
  LightningLine(long startTime, float startY, float startTheta, float basicAngle, float propagationSpeed, float lineWidth, int recursionDepthLeft, float forkingChance){
    this.propagationSpeed = propagationSpeed;
    this.lineWidth = lineWidth;
    this.startY = startY;
    this.startTime = startTime;
    float y = startY;
    float theta = startTheta;
    float straightLineTheta;
    addKeyPoint(y, theta);
    while (y > treeBottomY){
      y -= (25 + MathUtils.random(75));
      if (y > 450){
        theta = startTheta - 20 + MathUtils.random(40);
      }
      else {
        straightLineTheta = startTheta + MathUtils.sin((MathUtils.TWO_PI/360) * basicAngle) * (startY - y) * 0.9f;
        theta = straightLineTheta - 50 + MathUtils.random(100);
      }
      addKeyPoint(y, theta);
      if (recursionDepthLeft > 0 && y < 500 && MathUtils.random(20) < forkingChance){
        forks.add(new LightningLine(startTime + (int)((startY - y) / propagationSpeed), y, theta,(-basicAngle * MathUtils.random(2)), propagationSpeed, (lineWidth - MathUtils.random(2)), recursionDepthLeft - 1, forkingChance));
      }
    }
  }
  public float getLightningFactor (float yToCheck, float thetaToCheck){
    float yLowerLimit = startY - (System.currentTimeMillis() - startTime) * (propagationSpeed);
    if (lifeCycleState == 0 && yLowerLimit < treeBottomY){
      lifeCycleState = 1;
      wideningStartTime = System.currentTimeMillis();
    }
    if (lifeCycleState == 1 && System.currentTimeMillis() > startTime + 2000 / propagationSpeed){
      lifeCycleState = 2;
    }
    if (lifeCycleState > 1 || yLowerLimit > yToCheck){
      return 0;
    }
    int i = 0;
    int keyPointIndex = -1;
    float result = 0;
    while (i < (yKeyPoints.length - 1)){
      if (yKeyPoints[i] > yToCheck && yKeyPoints[i + 1] <= yToCheck){
        keyPointIndex = i;
        i = yKeyPoints.length;
      }
      i++;
    }
    if (keyPointIndex >= 0){
      float targetTheta = thetaKeyPoints[keyPointIndex] + (thetaKeyPoints[keyPointIndex + 1] - thetaKeyPoints[keyPointIndex]) * (yKeyPoints[keyPointIndex] - yToCheck) /(yKeyPoints[keyPointIndex] - yKeyPoints[keyPointIndex + 1]);
      float thetaDelta = LXUtils.wrapdistf(targetTheta, thetaToCheck, 360);
      float thinnedLineWidth;
      if (lifeCycleState == 0){
        thinnedLineWidth = lineWidth / 2;
      }
      else {
        thinnedLineWidth = lineWidth / (Math.max(1, 2 - propagationSpeed * ((float)System.currentTimeMillis() - wideningStartTime) / 500));
      }
      result = Math.max(0, 100 * (thinnedLineWidth - thetaDelta) / lineWidth);
    }
    for (i=0; i < forks.size(); i++){
      result = Math.max(result, forks.get(i).getLightningFactor(yToCheck, thetaToCheck));
    }
    return result;
  }
  private void addKeyPoint(float y, float theta){
    yKeyPoints = ArrayUtils.add(yKeyPoints, y);
    thetaKeyPoints = ArrayUtils.add(thetaKeyPoints, theta);
  }
  public boolean isDead(){
    return lifeCycleState > 1;
  }
}


class IceCrystals extends TSPattern {
  private IceCrystalLine crystal;
  final BasicParameter propagationSpeed = new BasicParameter("Speed", 5, 1, 20);
  final BasicParameter lineWidth = new BasicParameter("Width", 60, 20, 150);
  final DiscreteParameter recursionDepth = new DiscreteParameter("Danger", 7, 12);
  final IceCrystalSettings settingsObj; 

  IceCrystals(LX lx) {
    super(lx);
    addParameter(propagationSpeed);
    addParameter(lineWidth);
    addParameter(recursionDepth);
    recursionDepth.setRange(5, 14);
    settingsObj = new IceCrystalSettings(14);
    crystal = new IceCrystalLine(0, settingsObj);
  }
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) {
      if (crystal.lifeCycleState != -1) {
        crystal.doReset();
      }
      return;
    }
    
    if (crystal.isDone()){
      startCrystal();
    }
    crystal.doUpdate();
    for (Cube cube : model.cubes) {
      float lineFactor = crystal.getLineFactor(cube.transformedY, cube.transformedTheta);
      if (lineFactor > 110) {
        lineFactor = 200 - lineFactor;  
      }
      float hueVal;
      float satVal;
      float brightVal = Math.min(100, 20 + lineFactor);
      if (lineFactor > 100){
        brightVal = 100;
        hueVal = 180;
        satVal = 0;
      }
      else if (lineFactor < 20){
        hueVal = 220;
        satVal = 100;
      }
      else if (lineFactor < 50){
        hueVal = 240;
        satVal = 60;
      }
      else {
        hueVal = 240;
        satVal = 60 - 60 * (lineFactor / 100);
      }
      colors[cube.index] = lx.hsb(hueVal,  satVal, brightVal);
    }
  }
  void startCrystal(){
    crystal.doReset();
    settingsObj.doSettings(recursionDepth.getValuei(), lineWidth.getValuef(), 150, propagationSpeed.getValuef());
    crystal.doStart(100, MathUtils.random(360), (7 + (int)MathUtils.random(2.9f)) % 8);
  }

  Triggerable getTriggerable() {
    return new ParameterTriggerableAdapter(lx, getChannel().getFader()) {
      public void onTriggered(float strength) {
        startCrystal();
        super.onTriggered(strength);
      }
    };
  }
}
class IceCrystalSettings {
  protected int totalRecursionDepth;
  protected float baseLineWidth;
  protected float baseLineLength;
  protected float basePropagationSpeed;
  protected float[] lineLengths;
  protected boolean growthFinished = false;
  protected long growthFinishedTime = 0;
  protected final int maxRecursionDepth;
  IceCrystalSettings(int maxRecursionDepth){
    this.maxRecursionDepth = maxRecursionDepth;
  }
  public void doSettings(int totalRecursionDepth, float baseLineWidth, float baseLineLength, float basePropagationSpeed) {
    this.totalRecursionDepth = totalRecursionDepth;
    this.baseLineWidth = baseLineWidth;
    this.baseLineLength = baseLineLength;
    this.basePropagationSpeed = basePropagationSpeed;
    growthFinishedTime = 0;
    growthFinished = false;
    lineLengths = new float[totalRecursionDepth + 1];
    for (int i=0; i <= totalRecursionDepth; i++){
      lineLengths[i] =  (float)Math.pow(0.9f, i) * (0.5f + MathUtils.random(1)) * baseLineLength;
    }
  }
  
  public float getLineWidth(int recursionDepth){
    return baseLineWidth * (float)Math.pow(0.9, recursionDepth);
  }
  public float getLineLength(int recursionDepth){
    return lineLengths[recursionDepth];
  }
  public float getPropagationSpeed(int recursionDepth){
    return basePropagationSpeed * (float)Math.pow(0.8, recursionDepth);
  }
  public void setGrowthFinished(){
    if (!growthFinished){
      growthFinishedTime = System.currentTimeMillis();
    }
    growthFinished = true;
  }
}
class IceCrystalLine {
  protected int lifeCycleState = -1;
  private final int recursionDepth;
  private long startTime;
  private float startY;
  private float startTheta;
  private float endY;
  private float endTheta;
  private float propagationSpeed;
  private float lineLength;
  private float lineWidth;
  private int angleIndex;
  private long lifeCycleStateChangeTime;
  private final float[][] angleFactors = {{0, 1}, {0.7071f, 0.7071f}, {1, 0}, {0.7071f, -0.7071f}, {0, -1}, {-0.7071f, -0.7071f}, {-1, 0}, {-0.7071f, 0.7071f}};
  private IceCrystalLine[] children = new IceCrystalLine[2];
  protected float[][] applicableRange = {{0, 0}, {0, 0}};
  private float nodeMeltRadius;
  protected boolean hasChildren = false;
  private IceCrystalSettings settings;
  IceCrystalLine(int recursionDepth, IceCrystalSettings settings){
    this.recursionDepth = recursionDepth;
    this.settings = settings;
    if (recursionDepth < settings.maxRecursionDepth){
      children[0] = new IceCrystalLine(recursionDepth + 1,  settings);
      children[1] = new IceCrystalLine(recursionDepth + 1,  settings);
    }
  }
  public void doStart(float startY, float startTheta, int angleIndex){
    lifeCycleState = 0;
    this.angleIndex = angleIndex;
    this.startY = startY;
    this.startTheta = 360 + (startTheta % 360);
    this.propagationSpeed = settings.getPropagationSpeed(recursionDepth);
    lineLength = settings.getLineLength(recursionDepth);
    lineWidth = settings.getLineWidth(recursionDepth);
    startTime = System.currentTimeMillis();
    doUpdate();
  }
  public void doReset(){
    lifeCycleState = -1;
    hasChildren = false;
    nodeMeltRadius = 0;
    if (recursionDepth < settings.maxRecursionDepth){
      children[0].doReset();
      children[1].doReset();
    }
  }
  
  public void doUpdate(){
    switch(lifeCycleState){
      case 0: //this line is growing
        float currentLineLength = (System.currentTimeMillis() - startTime) * propagationSpeed / 10;
        if (currentLineLength > lineLength) {
          currentLineLength = lineLength;
          if (recursionDepth >= settings.totalRecursionDepth){
            settings.setGrowthFinished();
            changeLifeCycleState(3);
          }
          else {
            changeLifeCycleState((endY < 0 || endY >  800) ? 3 : 1);
          }
        }
        endTheta = startTheta + angleFactors[angleIndex][0] * currentLineLength;
        endY = startY + angleFactors[angleIndex][1] * currentLineLength;
        applicableRange[0][0] = Math.min(startTheta, endTheta) - lineWidth / 2;
        applicableRange[0][1] = Math.max(startTheta, endTheta) + lineWidth / 2;
        applicableRange[1][0] = Math.min(startY, endY) - lineWidth / 2;
        applicableRange[1][1] = Math.max(startY, endY) + lineWidth / 2;
      break;
      case 1: // creating children (wohoo!)
        children[0].doStart(endY, endTheta % 360, (8 + angleIndex - 1) % 8);
        children[1].doStart(endY, endTheta % 360, (angleIndex + 1) % 8);
        changeLifeCycleState(2);
        hasChildren = true;
      break;
      case 2: //has children that are growing
        checkRangeOfChildren();
      break;
      case 3: // frozen
        if (recursionDepth <= 3 && settings.growthFinished && settings.growthFinishedTime < (System.currentTimeMillis() - 8000 / propagationSpeed)){
          changeLifeCycleState(4);
        }
      break;
      case 4: // melting
        nodeMeltRadius = (float)Math.pow((settings.totalRecursionDepth - recursionDepth) * (System.currentTimeMillis() - lifeCycleStateChangeTime) * propagationSpeed  / 7000, 2) ;
        applicableRange[0][0] = Math.min(applicableRange[0][0], Math.max(0, endTheta - nodeMeltRadius));
        applicableRange[0][1] = Math.max(applicableRange[0][1], Math.min(720, endTheta + nodeMeltRadius));
        applicableRange[1][0] = Math.min(applicableRange[1][0], Math.max(100, (endY - nodeMeltRadius)));
        applicableRange[1][1] = Math.max(applicableRange[1][1], Math.min(700, (endY + nodeMeltRadius)));
        if (lifeCycleStateChangeTime < (System.currentTimeMillis() - 27000 / propagationSpeed)){
          changeLifeCycleState(5);
          children[0].doReset();
          children[1].doReset();
          hasChildren = false;
        }
      break;
      case 5: //water
        if (lifeCycleStateChangeTime < (System.currentTimeMillis() - 8000 / propagationSpeed)){
          changeLifeCycleState(6);
        }
      break;
      case 6: // done
      break;
    }
    if (hasChildren && lifeCycleState >= 2 && lifeCycleState <= 4){
      children[0].doUpdate();
      children[1].doUpdate();
      if (children[0].lifeCycleState == children[1].lifeCycleState && lifeCycleState < children[0].lifeCycleState){
        changeLifeCycleState(children[0].lifeCycleState);
      }
    }
  }
  public float getLineFactor (float yToCheck, float thetaToCheck){
    float result = 0;
    if (lifeCycleState >= 5){
      return 200;
    }
    if (yToCheck <= applicableRange[1][0] || yToCheck >= applicableRange[1][1]){
      return result;
    }
    float adjustedTheta = thetaToCheck < applicableRange[0][0] ? thetaToCheck + 360 : thetaToCheck;
    if (!(adjustedTheta >= applicableRange[0][0] && adjustedTheta <= applicableRange[0][1])){
      return result;
    }
    if (lifeCycleState == 4){
      float distFromNode = (float)Math.sqrt((float)Math.pow(Math.abs(endY - yToCheck), 2) + (float)Math.pow(LXUtils.wrapdistf(endTheta, thetaToCheck, 360), 2));
      if (distFromNode < nodeMeltRadius){
        result = Math.min(200, 100 + 150 * (nodeMeltRadius - distFromNode) / nodeMeltRadius);
      }
    }
    float lowestY = Math.min(startY, endY);
    float highestY = Math.max(startY, endY);
    if (Math.abs(angleFactors[angleIndex][1]) > 0){
     if (yToCheck >= lowestY && yToCheck <= highestY){
        float targetTheta = startTheta + (endTheta - startTheta) * (yToCheck - startY) / (endY - startY);
        float lineThetaWidth = lineWidth / (2 * Math.abs(angleFactors[angleIndex][1]));
        result = Math.max(result, 100 * Math.max(0, (lineThetaWidth - Math.abs(LXUtils.wrapdistf(targetTheta, thetaToCheck, 360)))) / lineThetaWidth);
      }
    }
    else {
      float lowestTheta = Math.min(startTheta, endTheta);
      float highestTheta = Math.max(startTheta, endTheta);
      if (thetaToCheck < lowestTheta) {
        thetaToCheck += 360;
      }
      if (thetaToCheck >= lowestTheta && thetaToCheck <= highestTheta){
        if (yToCheck <= lowestY && yToCheck >= lowestY - lineWidth / 2){
          result = Math.max(result, 100 * (lineWidth / 2 - (lowestY - yToCheck)) / (lineWidth / 2));
        }
        if (yToCheck >= highestY && yToCheck <= highestY + lineWidth / 2){
          result = Math.max(result, 100 * (lineWidth / 2 - (yToCheck - highestY)) / (lineWidth / 2));
        }
      }
    }
    if (lifeCycleState >= 2 && hasChildren){
      result = Math.max(result, Math.max(children[0].getLineFactor(yToCheck, thetaToCheck % 360), children[1].getLineFactor(yToCheck, thetaToCheck % 360)));
    }
    return result;
  }
  public void checkRangeOfChildren(){
    if (hasChildren){
      for (int i = 0; i < children.length; i++){
        for (int j = 0; j < 2; j++){
          applicableRange[j][0] = Math.min(applicableRange[j][0], children[i].applicableRange[j][0]);
          applicableRange[j][1] = Math.max(applicableRange[j][1], children[i].applicableRange[j][1]);
        }
      }
    }
  }
  void changeLifeCycleState(int lifeCycleStateIn){
    lifeCycleStateChangeTime = System.currentTimeMillis();
    this.lifeCycleState = lifeCycleStateIn;
  }
  public boolean isDone(){
    return lifeCycleState == 6 || lifeCycleState == -1;
  }
}



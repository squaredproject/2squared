class APattern extends MultiObjectPattern<SnowFlake> {
  
  APattern(LX lx) {
    super(lx);
  }
  
  BasicParameter getFrequencyParameter() {
    return new BasicParameter("FREQ", 40, .1, 400, BasicParameter.Scaling.QUAD_IN);
  }
   
  SnowFlake generateObject(float strength) {
    SnowFlake snowFlake = new SnowFlake(lx);
    snowFlake.runningTimer = 0;
    snowFlake.runningTimerEnd = 90 + random(50);
    snowFlake.decayTime = snowFlake.runningTimerEnd;
    float pathDirection = 270;
    snowFlake.pathDist = model.yMax - model.yMin + 40;
    snowFlake.startTheta = random(160);
    snowFlake.startY = model.yMax + 20;
    snowFlake.startPoint = new PVector(snowFlake.startTheta, snowFlake.startY);
    snowFlake.endTheta = snowFlake.startTheta;
    snowFlake.endY = model.yMin - 20;
    snowFlake.displayColor = 200 + (int)random(20);
    snowFlake.thickness = .5 + random(.6);
    
    return snowFlake;
  }
}

class SnowFlake extends MultiObject {
  
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
  
  SnowFlake(LX lx) {
    super(lx);
  }
  
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
    PVector cubePointPrime = movePointToSamePlane(currentPoint, cube.transformedCylinderPoint);
    float distFromSource = PVector.dist(cubePointPrime, currentPoint);
    float tailFadeFactor = distFromSource / pathDist;
    return lx.hsb(displayColor, 60, max(5, (100 - 10 * distFromSource / thickness)));
  }
}

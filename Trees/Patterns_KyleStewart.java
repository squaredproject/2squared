import heronarts.lx.LX;
import heronarts.lx.LXUtils;
import heronarts.lx.parameter.BasicParameter;

import toxi.geom.Vec2D;
import toxi.math.MathUtils;

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
    snowFlake.runningTimerEnd = 90 + MathUtils.random(50f);
    snowFlake.decayTime = snowFlake.runningTimerEnd;
    float pathDirection = 270;
    snowFlake.pathDist = model.yMax - model.yMin + 40;
    snowFlake.startTheta = MathUtils.random(160f);
    snowFlake.startY = model.yMax + 20;
    snowFlake.startPoint = new Vec2D(snowFlake.startTheta, snowFlake.startY);
    snowFlake.endTheta = snowFlake.startTheta;
    snowFlake.endY = model.yMin - 20;
    snowFlake.displayColor = 200 + (int)MathUtils.random(20f);
    snowFlake.thickness = .5f + MathUtils.random(.6f);
    
    return snowFlake;
  }
}

class SnowFlake extends MultiObject {
  
  float runningTimer;
  float runningTimerEnd;
  float decayTime;
  
  Vec2D startPoint;
  float startTheta;
  float startY;
  float endTheta;
  float endY;
  float pathDist;
  
  int displayColor;
  float thickness;
  
  float percentDone;
  Vec2D currentPoint;
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
        percentDone = Math.min(runningTimer, runningTimerEnd) / runningTimerEnd;
        currentTheta = (float)LXUtils.lerp(startTheta, endTheta, percentDone);
        currentY = (float)LXUtils.lerp(startY, endY, percentDone);
        currentPoint = new Vec2D(currentTheta, currentY);
      }
    }
  }
  
  public int getColorForCube(Cube cube) {
    Vec2D cubePointPrime = VecUtils.movePointToSamePlane(currentPoint, cube.transformedCylinderPoint);
    float distFromSource = cubePointPrime.distanceTo(currentPoint);
    float tailFadeFactor = distFromSource / pathDist;
    return lx.hsb(displayColor, 60, Math.max(5, (100 - 10 * distFromSource / thickness)));
  }
}

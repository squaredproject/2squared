public class PixelState {
  LX lx;
  double when; // time last triggered (possibly zero)
  float h, s, life; // parameters when last triggered
  
  PixelState(LX _lx) {
    lx = _lx;
    when = -1000 * 60 * 60; // arbitrary time far in the past
    h = s = life = 0;
  }
  
  public void fire(double now, float _life, float _h, float _s) {
    when = now;
    life = _life;
    h = _h;
    s = _s;
  }
  
  public color currentColor(double now) {
    double age = (life - (now - when)) / life;
    if (age < 0)
      age = 0;
    return lx.hsb(h * 360, s * 100, age * 100);
  }
}

class Pixels extends LXPattern {
  final BasicParameter pSpeed = new BasicParameter("SPD", 2.0/15.0);
  final BasicParameter pLifetime = new BasicParameter("LIFE", 3.0/15.0);
  final BasicParameter pHue = new BasicParameter("HUE", 0.5);
  final BasicParameter pSat = new BasicParameter("SAT", 0.5);
  final SawLFO hueLFO = new SawLFO(0.0, 1.0, 1000);

  PixelState[] pixelStates;
  double now = 0;
  double lastFireTime = 0;
  
  Pixels(LX lx) {
    super(lx);
    
    addParameter(pSpeed);
    addParameter(pLifetime);
    addParameter(pSat);
    addParameter(pHue);
    addModulator(hueLFO.start());

    int numCubes = model.cubes.size();
    pixelStates = new PixelState[numCubes];
    for (int n = 0; n < numCubes; n++)
      pixelStates[n] = new PixelState(lx);
  }
  
  public void run(double deltaMs) {
    now += deltaMs;
    
    float vSpeed = pSpeed.getValuef();
    float vLifetime = pLifetime.getValuef();
    float vHue = pHue.getValuef();
    float vSat = pSat.getValuef();

    hueLFO.setPeriod(vHue * 30000 + 1000);
    
    float minFiresPerSec = 5;
    float maxFiresPerSec = 2000;
    float firesPerSec = minFiresPerSec + vSpeed * (maxFiresPerSec - minFiresPerSec);
    float timeBetween = 1000 / firesPerSec;
    while (lastFireTime + timeBetween < now) {
      int which = (int)random(0, model.cubes.size());
      pixelStates[which].fire(now, vLifetime * 1000 + 10, hueLFO.getValuef(), (1 - vSat));
      lastFireTime += timeBetween;
    } 
    
    int i = 0;
    for (i = 0; i < model.cubes.size(); i++) {
      colors[i] = pixelStates[i].currentColor(now);
    }
  }
}

///////////////////////////////////////////////////////////////////////////////

class Wedges extends LXPattern {
  final BasicParameter pSpeed = new BasicParameter("SPD", .52);
  final BasicParameter pCount = new BasicParameter("COUNT", 4.0/15.0);
  final BasicParameter pSat = new BasicParameter("SAT", 5.0/15.0);
  final BasicParameter pHue = new BasicParameter("HUE", .5);
  double rotation = 0; // degrees

  Wedges(LX lx) {
    super(lx);
    
    addParameter(pSpeed);
    addParameter(pCount);
    addParameter(pSat);
    addParameter(pHue);
    rotation = 0;
  }
  
  public void run(double deltaMs) {
    float vSpeed = pSpeed.getValuef();
    float vCount = pCount.getValuef();
    float vSat = pSat.getValuef();
    float vHue = pHue.getValuef();

    rotation += deltaMs/1000.0 * (2 * (vSpeed - .5) * 360.0 * 1.0);
    rotation = rotation % 360.0;

    double sections = Math.floor(1.0 + vCount * 10.0);
    double quant = 360.0/sections;

    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        Math.floor((rotation - cube.theta) / quant) * quant + vHue * 360.0,
        (1 - vSat) * 100,
        100);
    }     
  } 
}


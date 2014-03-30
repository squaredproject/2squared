import codeanticode.syphon.*;

PGraphics buffer;
PImage imgbuffer;
SyphonClient client;

class SyphonPattern extends LXPattern {

  int x, y, z = 0;
  float xscale, yscale = 0f;
  int[] xpoints, ypoints;

  final DiscreteParameter getWidth = new DiscreteParameter("GW", 1, 10);
  final DiscreteParameter mode = new DiscreteParameter("MODE", 1, 10);

  SyphonPattern(LX lx, PApplet applet) {
    super(lx);
    addParameter(getWidth);
    addParameter(mode);
    client = new SyphonClient(applet, "Modul8", "Main View");
    xpoints = new int[model.cubes.size()];
    ypoints = new int[model.cubes.size()];
  }

  void generateMap(int buffWidth, int buffHeight) {
    this.xscale = buffWidth / model.xRange;
    this.yscale = buffHeight / model.yRange;
    int cubeIdx = 0;    
    for (Cube cube : model.cubes) {
      xpoints[cubeIdx] = int((cube.cx - model.xMin) * this.xscale);
      ypoints[cubeIdx] = buffHeight - int((cube.cy - model.yMin) * this.yscale);    
      cubeIdx++;
    }
  }

  public void run(double deltaMs) {
    if (client.available()) {

      buffer = client.getGraphics(buffer);
      imgbuffer = buffer.get();
      if (this.xscale == 0) {
        generateMap(buffer.width, buffer.height);
      }
      int cubeIdx = 0;
      for (Cube cube : model.cubes) {
        color c = weighted_get(imgbuffer, xpoints[cubeIdx], ypoints[cubeIdx], getWidth.getValuei());
        setColor(cube, c);
        cubeIdx++;
      }
    }
  }
  
  private boolean restoreThreaded = false;
  private int syphonCount = 0;
  
  public void onActive() {
    if (syphonCount == 0) {
      if (restoreThreaded = lx.engine.isThreaded()) {
        lx.engine.setThreaded(false);
      }
    }
    ++syphonCount; 
  }
  
  public void onInactive() {
    --syphonCount;
    if ((syphonCount == 0) && restoreThreaded) {
      lx.engine.setThreaded(true);
    }
  }
}


color weighted_get(PImage imgbuffer, int xpos, int ypos, int radius) {
  int h, s, b;
  int xoffset, yoffset;
  int pixels_counted;

  color thispixel;


  h = s = b = pixels_counted = 0;

  for (xoffset=-radius; xoffset<radius; xoffset++) {
    for (yoffset=-radius; yoffset<radius; yoffset++) {

      pixels_counted ++;
      thispixel = imgbuffer.get(xpos + xoffset, ypos + yoffset);

      h += hue(thispixel);
      s += saturation(thispixel);
      b += brightness(thispixel);
    }
  }
  return color(h/pixels_counted, s/pixels_counted, b/pixels_counted);
}

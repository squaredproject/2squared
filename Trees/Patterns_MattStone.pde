import codeanticode.syphon.*;

PGraphics buffer;
PImage imgbuffer;
SyphonClient client;

class SyphonPattern extends LXPattern {

  int x, y, z = 0;
  float xscale, yscale = 0f;
  int[] xpoints, ypoints;

  SyphonPattern(LX lx, PApplet applet) {
    super(lx);
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
      ypoints[cubeIdx] = int((cube.cy - model.yMin) * this.yscale);    
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
        color c = imgbuffer.get(xpoints[cubeIdx], ypoints[cubeIdx]);
        setColor(cube, c);
        cubeIdx++;
      }
    }
  }
}

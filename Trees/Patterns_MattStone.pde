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
        //color c = imgbuffer.get(xpoints[cubeIdx], ypoints[cubeIdx]);
        color c = weighted_get(imgbuffer, xpoints[cubeIdx], ypoints[cubeIdx], 2);
        setColor(cube, c);
        cubeIdx++;
      }
    }
  }
}


color weighted_get(PImage imgbuffer, int xpos, int ypos, int radius) {
   int red, green, blue;
   int xoffset, yoffset;
   int pixels_counted;
  
   color thispixel;
  
  
  red = green = blue = pixels_counted = 0;

    for (xoffset=-radius; xoffset<radius; xoffset++) {
     for (yoffset=-radius; yoffset<radius; yoffset++) {

        pixels_counted ++;
        thispixel = imgbuffer.get(xpos + xoffset, ypos + yoffset);
        red += red(thispixel);
        green += green(thispixel);
        blue += blue(thispixel);
      }
  }
  return color(red/pixels_counted, green/pixels_counted, blue/pixels_counted);       
}



class CameraWrap extends TSPattern {
  
  // These parameters will be used to control how the image
  // is stretched around the tree ...
  final BasicParameter p1 = new BasicParameter("EXP", 0.25);
  final BasicParameter p2 = new BasicParameter("WID", 0.25);

  private VideoFeed vid = null;

  public CameraWrap(LX lx) {
    super(lx);

    // Makes the parameters have knobs in the UI
    addParameter(p1);
    addParameter(p2);
  }

  public void onActive() {
    // Startup the webcam first time we are active
    if (vid == null) {
      vid = new VideoFeed(Trees.this);
      vid.start();
    }
  }

  // This depends on the wrapping mode.
  // Return x,y of source pixel; use a
  // kernel to average nearby pixels

  int[] GetImageXYFromCube(Cube cube) {
    
      final float treeHeight = Trees.this.height;
    
      float x = cube.theta*(float)vid.width()/360.;
      float y = cube.z*vid.height()/treeHeight;
    
      int[] xy = { (int)x, (int)y };
      return xy;
  }
  
  int[] pixels;
  double timeSincePrevRead = 0.0;
  
  // This is your run loop called every frame.
  // It's basically just like Processing's draw()  
  public void run(double deltaMs) {

    vid.fetch(); // this only updates pixels when a new image is available.
    pixels = vid.pixels();

    if (pixels==null || pixels.length==0) return;

    // These are the values of your knobs
    float p1v = p1.getValuef();
    float p2v = p2.getValuef();
    
    // These are the values of the LFOs
    //float vpf = verticalPosition.getValuef();
    //float apf = anglePosition.getValuef();
    
    // So it can work when there is more than 1 ..
    for (Tree tree : model.trees) {
      for (Cube cube : tree.cubes) {
        // This passes through every cube in the tree
        // cubes have:
        //   .x, .y, .z (absolute position in inches)
        //   .tx, .ty, .tz (position relative to tree base, in inches)
        //   .theta (angle about the center of tree, 0-360)
        //   .size (which size cube this is, Cube.SMALL/Cube.MEDIUM/Cube.LARGE/Cube.GIANT
       	// 
        // Color space for lx.hsb:
        //   h: 0-360
        //   s: 0-100
        //   b: 0-100
        
	int[] imgPt = GetImageXYFromCube(cube);
	int idx = vid.height()*imgPt[0]+imgPt[1];
	// TODO - average local image area with an appropriate kernel
        colors[cube.index] = pixels[idx];
      }
    }

  } // end of run(..)

}


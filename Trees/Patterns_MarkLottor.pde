class MarkLottor extends LXPattern {
  
  // These parameters will be knobs on the UI
  final BasicParameter p1 = new BasicParameter("P1", 0);
  final BasicParameter p2 = new BasicParameter("P2", 0);
  final BasicParameter p3 = new BasicParameter("P3", 0);
  final BasicParameter p4 = new BasicParameter("P4", 0);
  
  // This is an example modulator
  final SinLFO verticalPosition = new SinLFO(model.yMin, model.yMax, 5000);
  
  // This is an example of using cube theta
  final SawLFO anglePosition = new SawLFO(0, 360, 2000);
  
  MarkLottor(LX lx) {
    super(lx);
    
    // Makes the parameters have knobs in the UI
    addParameter(p1);
    addParameter(p2);
    addParameter(p3);
    addParameter(p4);
    
    // Starts the modulators
    addModulator(verticalPosition.start());
    addModulator(anglePosition.start());
  }
  
  // This is your run loop called every frame.
  // It's basically just like Processing's draw()  
  public void run(double deltaMs) {
    // These are the values of your knobs
    float p1v = p1.getValuef();
    float p2v = p2.getValuef();
    float p3v = p3.getValuef();
    float p4v = p4.getValuef();
    
    // These are the values of the LFOs
    float vpf = verticalPosition.getValuef();
    float apf = anglePosition.getValuef();
    
    for (Tree tree : model.trees) {
      // There will be two passes through this loop, one for each tree
      if (tree.index == 1) {
        // Make second tree rotate the other way
        apf = 360-apf;
      }
      
      for (Cube cube : tree.cubes) {
        // This passes through every cube in the tree
        // cubes have:
        //   .x, .y, .z (absolute position in inches)
        //   .tx, .ty, .tz (position relative to tree base, in inches)
        //   .theta (angle about the center of tree, 0-360)
        
        // Color space for lx.hsb:
        //   h: 0-360
        //   s: 0-100
        //   b: 0-100
        
        colors[cube.index] = lx.hsb(
          (lx.getBaseHuef() + cube.y * .3) % 360,
          100,
          max(0, 100 - LXUtils.wrapdistf(cube.theta, apf, 360))
        );
      }
    }
      
  }
}


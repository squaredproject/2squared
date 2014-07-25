class AcidTrip extends LXPattern {
  
  final SinLFO range = new SinLFO(-50, 50, 10000);
  final SawLFO trails = new SawLFO(364, 0, 7000);
  
  float cx = (int)model.cx;
  float cy = (int)model.cy;
  
  AcidTrip(LX lx) {
    super(lx);
    addModulator(trails.start());
    addModulator(range.start());
  }
    
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
   
     for (Cube cube : model.cubes) {
      
         colors[cube.index] = lx.hsb(
           abs(cy - cube.y) + abs(cy - cube.x) + trails.getValuef() % 360,
           100,
           100
         );
       
     }
    
  }
  
}

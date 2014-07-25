class Zebra extends LXPattern {
 
 BasicParameter thickness =  new BasicParameter ("THIC", 160,0,200); 
 BasicParameter  period= new BasicParameter ("PERI", 500, 300, 3000);
  double timer = 0;
  
  SinLFO position =new SinLFO(0, 200, period);
  
  Zebra(LX lx) {
    super(lx);
    addParameter(thickness);
    addParameter(period);
    addModulator(position.start());
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
    
    timer = timer + deltaMs;
    for (Cube cube : model.cubes){
    float hue = .4;
    float saturation;
    float brightness = 1;
    
    if (((cube.y + position.getValue() + cube.theta) % 200) > thickness.getValue()) {
      saturation=0;
      brightness=1;
    } else {
      saturation=1;
      brightness=0;
    }
    
    colors[cube.index] = lx.hsb (
    360 * hue, 
    100 * saturation,
    100 * brightness
   );
  }
 }
}

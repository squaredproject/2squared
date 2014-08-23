// copied from Patterns_Alchemy
class Spinny extends TSPattern {
 
 BasicParameter thickness =  new BasicParameter ("THIC", 100,0,200); 
 BasicParameter  period= new BasicParameter ("PERI", 500, 300, 7000);
  double timer = 0;
  
  SinLFO position =new SinLFO(0, 100, period);
  
  Spinny(LX lx) {
    super(lx);
    addParameter(thickness);
    addParameter(period);
    addModulator(position).start();
  }
  
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
    
    timer = timer + deltaMs;
    for (Cube cube : model.cubes){
    float hue = 0.55;
    float saturation;
    float brightness = 1;
    
    if (((cube.transformedY + position.getValue() + cube.transformedTheta) % 200) > thickness.getValue()) {
      saturation=0.75;
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

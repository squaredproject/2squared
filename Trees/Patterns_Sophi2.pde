// copied from Patterns_Alchemy
class Verty extends TSPattern {
  int thick = 650;
  float hue = 0.00; //hue go from 0.585 to 0.7 to stay blue
  double scroll;
  int delay = millis();
  int second = second();
  int flag;
  //want: stripes to keep going, not reset so at y = 360, y =0, also want stripes to change blue values
  //go thru cycle then rain white dots
  BasicParameter thickness =  new BasicParameter ("THIC", thick, 0, 100); 
  BasicParameter  period= new BasicParameter ("PERI", 900, 900, 10000);
  double timer = 0;

  SawLFO position =new SawLFO(0, 800, period.getValue()*2); //start, end, period ms, frequency
  Verty(LX lx) {
    super(lx);
    addParameter(thickness);
    addParameter(period);
    addModulator(position).start();
  }
  void sec() {
    if (second >= 1) {
     hue = hue + 0.0001;
      second = 0;
    }
  }

  public void run(double deltaMs) {
    sec();
    second++;
    if (getChannel().getFader().getNormalized() == 0) return;

    timer = timer + deltaMs;
    for (Cube cube : model.cubes) {       
      float saturation;
      float brightness = 1;
    
     if (position.getValue() >= 0) {     
        //cube.transformedY = 0; //flips the pattern vertically
        cube.transformedTheta = 0;
      }

      if (((cube.transformedY + position.getValue() + cube.transformedTheta) % 200) > thickness.getValue()) {
        saturation=0.75;
        brightness=1;  
        if (hue >= 0.75) {
          hue = 0.5;
        }
      } else {
        saturation=0.75;
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


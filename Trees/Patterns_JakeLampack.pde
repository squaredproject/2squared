class AcidTrip extends TSPattern {
  
  final SawLFO trails = new SawLFO(360, 0, 7000);
  
  AcidTrip(LX lx) {
    super(lx);

    addModulator(trails).start();
  }
    
  public void run(double deltaMs) {
    for (Cube cube : model.cubes) {
      colors[cube.index] = lx.hsb(
        abs(model.cy - cube.transformedY) + abs(model.cy - cube.transformedTheta) + trails.getValuef() % 360,
        100,
        100
      );
    }
  }
}


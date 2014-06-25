class TSDrumpad implements Drumpad {
  
  TriggerablePattern[] patterns = null;
  
  private TriggerablePattern[] patterns(LX lx) {
    TriggerablePattern[] patterns = new TriggerablePattern[] {
      new Brightness(lx),
      new Explosions(lx),
      new Wisps(lx),
      new Lightning(lx),
      new Pulley(lx),
    };
    return patterns;
  }
  
  void configure(LX lx) {
    patterns = patterns(lx);
    
    LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
    for (TriggerablePattern pattern : patterns) {
      LXPattern p = (LXPattern)pattern; // trust they extend lxpattern
      p.setTransition(t);
      pattern.enableTriggerableMode();
      LXChannel channel = lx.engine.addChannel(new LXPattern[] { p });
      channel.getFader().setValue(1);
      channel.setFaderTransition(new TreesTransition(lx, channel));
    }
  }
  
  public void padTriggered(int index, int velocity) {
    if (patterns != null && index < patterns.length) {
      patterns[index].onTriggered(velocity / 127.);
    }
  }
  
  public void padReleased(int index) {
    if (patterns != null && index < patterns.length) {
      patterns[index].onRelease();
    }
  }
}

interface TriggerablePattern {
  public void enableTriggerableMode();
  public void onTriggered(float strength);
  public void onRelease();
}


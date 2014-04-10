class UIMasterBpm extends UIWindow {
  UILabel bpmLabel;
  
  UIMasterBpm(UI ui, float x, float y) {
    super(ui, "MASTER BPM", x, y, 140, 78);
    (bpmLabel = new UILabel(4, TITLE_LABEL_HEIGHT - 3, 12 * 3, 20))
    .setLabel("120")
    .setAlignment(CENTER, CENTER)
    .setBorderColor(#666666)
    .setBackgroundColor(#292929)
    .addToContainer(this);
    
  }
}

class BPMTool extends LXEffect {

  final DiscreteParameter bpm = new DiscreteParameter("BPM", 0, 200); 
  
  BPMTool(LX lx) {
    super(lx);
  }
  

  public void apply(int[] colors) {
    if (isEnabled()) {
      // No-op
    }
  }
}

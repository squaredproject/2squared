class UIMasterBpm extends UIWindow {
  
  final static int BUTT_WIDTH = 12 * 3;
  final static int BUTT_HEIGHT = 20;
  final static int SPACING = 4;
  
  UIMasterBpm(UI ui, float x, float y) {
    super(ui, "MASTER BPM", x, y, 140, 78);
    int yPos = TITLE_LABEL_HEIGHT - 3;
    int xPos = SPACING * 2;

    new UILabel(xPos, yPos, 20, BUTT_HEIGHT)
    .setLabel("BPM: ")
    .setAlignment(LEFT, CENTER)
    .addToContainer(this);
    
    xPos += 20 + SPACING;
  
    new UIIntegerBox(xPos, yPos, BUTT_WIDTH * 2, BUTT_HEIGHT)
    .setParameter(bpmTool.bpm)
    .addToContainer(this);
       
    yPos += BUTT_HEIGHT + SPACING;

    xPos = SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH / 2, BUTT_HEIGHT)
    .setLabel("+")
    .setMomentary(true)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH / 2 + SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH / 2, BUTT_HEIGHT)
    .setLabel("-")
    .setMomentary(true)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH / 2 + SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH, BUTT_HEIGHT)
    .setLabel("SYNC")
    .setMomentary(true)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH + SPACING;
    
    new UIButton(xPos, yPos, BUTT_WIDTH, BUTT_HEIGHT)
    .setLabel("TAP")
    .setMomentary(true)
    .addToContainer(this);

  }
}

class BPMTool extends LXEffect {

  final DiscreteParameter bpm = new DiscreteParameter("BPM", 0, 300); 
  
  BPMTool(LX lx) {
    super(lx);
  }
  

  public void apply(int[] colors) {
    if (isEnabled()) {
      // No-op
    }
  }
}

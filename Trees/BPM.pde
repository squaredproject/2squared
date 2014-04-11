SinLFO bpmSinLfo = new SinLFO(0, 1, 0);
SawLFO bpmSawLfo = new SawLFO(0, 1, 0);
SquareLFO bpmSquareLfo = new SquareLFO(0, 1, 0);
TriangleLFO bpmTriangleLfo = new TriangleLFO(0, 1, 0);
QuadraticEnvelope bpmQuadraticLfo = new QuadraticEnvelope(0, 1, 0);

LXRangeModulator BPM_MODULATORS[] = {bpmSinLfo, bpmSawLfo, bpmQuadraticLfo, bpmSquareLfo, bpmTriangleLfo};
String[] bpmLabels = {"SIN", "SAW", "QD", "SQR", "TRI"};
LXRangeModulator selectedBpmModulator;


class UIMasterBpm extends UIWindow {
  
  final static int BUTT_WIDTH = 12 * 3;
  final static int BUTT_HEIGHT = 20;
  final static int SPACING = 4;
  
  
  UIMasterBpm(UI ui, float x, float y) {
    super(ui, "MASTER BPM", x, y, 140, 102);
    int yPos = TITLE_LABEL_HEIGHT - 3;
    int xPos = SPACING * 2;

    new UILabel(xPos, yPos, 20, BUTT_HEIGHT)
    .setLabel("BPM: ")
    .setAlignment(LEFT, CENTER)
    .addToContainer(this);
    
    xPos += 20 + SPACING;
  
    new UIIntegerBox(xPos, yPos, BUTT_WIDTH, BUTT_HEIGHT)
    .setParameter(bpmTool.bpm)
    .addToContainer(this);
    
    xPos += BUTT_WIDTH + SPACING;
         
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
    
    yPos += BUTT_HEIGHT + SPACING;
    
    for (int i = 0; i < 4; ++i) {
      new UIButton(5 + 34 * i, yPos, 28, 20)
      .setParameter(effectButtonParameters[i])
      .setMomentary(true)
      .setLabel(bpmLabels[i])
      .addToContainer(this);
    }

  }
}

class bpmListener implements LXParameterListener {
  
  public void onParameterChanged(LXParameter parameter) {
    double periodMs = 60000.0 / parameter.getValuef();
    for (LXRangeModulator modulator : BPM_MODULATORS) {
      modulator.setPeriod(periodMs);      
    }    
  }
}

public void startBpmModulators() {
  for (LXRangeModulator modulator : BPM_MODULATORS) {
      modulator.start();      
    } 
}

public void stopBpmModulators() {
  for (LXRangeModulator modulator : BPM_MODULATORS) {
      modulator.stop();      
    } 
}


class bpmSelectionListener implements LXParameterListener {
  
  LXRangeModulator modulator;
  
  bpmSelectionListener(LXRangeModulator modulator) {
    this.modulator = modulator;
  }
  
  public void onParameterChanged(LXParameter parameter) {
    if (parameter.getValue() > 0) {
          selectedBpmModulator = bpmSinLfo;
        } else {
          selectedBpmModulator = null;
        }
  }
}

class BPMTool {

  final DiscreteParameter bpm = new DiscreteParameter("BPM", 0, 300); 
  
  BPMTool() {    
    bpm.addListener(new bpmListener());
    startBpmModulators();
    for (int i = 0; i < effectButtonParameters.length; i++) {
      effectButtonParameters[i].addListener(new bpmSelectionListener(BPM_MODULATORS[i]));
    }    
  }
  

  public void apply(int[] colors) {
    if (isEnabled()) {
      // No-op
    }
  }
}

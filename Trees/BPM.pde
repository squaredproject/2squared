BPMSinLFO bpmSinLfo = new BPMSinLFO(0, 1, 0);
BPMSawLFO bpmSawLfo = new BPMSawLFO(0, 1, 0);
BPMSquareLFO bpmSquareLfo = new BPMSquareLFO(0, 1, 0);
//TriangleLFO bpmTriangleLfo = new TriangleLFO(0, 1, 0);
BPMQuadraticEnvelope bpmQuadraticLfo = new BPMQuadraticEnvelope(0, 1, 0);

LXRangeModulator BPM_MODULATORS[] = {bpmSinLfo, bpmSawLfo, bpmQuadraticLfo, bpmSquareLfo};
String[] bpmLabels = {"SIN", "SAW", "QD", "SQR"};
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
  
    new UISlider(xPos, yPos, BUTT_WIDTH, BUTT_HEIGHT)
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

  final BasicParameter bpm = new BasicParameter("BPM", 0, 300); 
  
  BPMTool() {    
    bpm.addListener(new bpmListener());
    startBpmModulators();
    for (int i = 0; i < effectButtonParameters.length; i++) {
      effectButtonParameters[i].addListener(new bpmSelectionListener(BPM_MODULATORS[i]));
    }    
  }
  
  public void AddBPMListener(LXPattern[] patterns) {
    for (LXPattern pattern : patterns) {
      for (LXParameter parameter : pattern.getParameters()) {        
        if (parameter instanceof LXListenableParameter) {
          //((LXListenableParameter)parameter).addListener()          
        }
      }
    }
  }
}

interface BPMLFO {
  
  public void AddBind(LXParameter parameter);
  public void RemoveBind(LXParameter parameter);
  
}

class BPMSinLFO extends SinLFO implements BPMLFO {

  List<LXParameter> binds;
  
  public BPMSinLFO(double startValue, double endValue, double periodMs) {
    super(startValue, endValue, periodMs);
    binds = new ArrayList<LXParameter>();  
  }
  
  public void AddBind(LXParameter parameter) {
    binds.add(parameter);
  }
  
  public void RemoveBind(LXParameter parameter) {
    binds.remove(parameter);
  }
  
  
  void onSetValue(double value) {
    super.onSetValue(value);
    for (LXParameter bind : binds) {
      bind.setValue(value);
    }
  }  
}

class BPMSawLFO extends SawLFO implements BPMLFO {

  List<LXParameter> binds;
  
  public BPMSawLFO(double startValue, double endValue, double periodMs) {
    super(startValue, endValue, periodMs);
    binds = new ArrayList<LXParameter>();  
  }
  
  public void AddBind(LXParameter parameter) {
    binds.add(parameter);
  }
  
  public void RemoveBind(LXParameter parameter) {
    binds.remove(parameter);
  }
  
  
  void onSetValue(double value) {
    super.onSetValue(value);
    for (LXParameter bind : binds) {
      bind.setValue(value);
    }
  }  
}

class BPMQuadraticEnvelope extends QuadraticEnvelope implements BPMLFO {

  List<LXParameter> binds;
  
  public BPMQuadraticEnvelope(double startValue, double endValue, double periodMs) {
    super(startValue, endValue, periodMs);
    binds = new ArrayList<LXParameter>();  
  }
  
  public void AddBind(LXParameter parameter) {
    binds.add(parameter);
  }
  
  public void RemoveBind(LXParameter parameter) {
    binds.remove(parameter);
  }
  
  
  void onSetValue(double value) {
    super.onSetValue(value);
    for (LXParameter bind : binds) {
      bind.setValue(value);
    }
  }  
}

class BPMSquareLFO extends SquareLFO implements BPMLFO {

  List<LXParameter> binds;
  
  public BPMSquareLFO(double startValue, double endValue, double periodMs) {
    super(startValue, endValue, periodMs);
    binds = new ArrayList<LXParameter>();  
  }
  
  public void AddBind(LXParameter parameter) {
    binds.add(parameter);
  }
  
  public void RemoveBind(LXParameter parameter) {
    binds.remove(parameter);
  }
  
  
  void onSetValue(double value) {
    super.onSetValue(value);
    for (LXParameter bind : binds) {
      bind.setValue(value);
    }
  }  
}

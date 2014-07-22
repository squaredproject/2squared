class UITrees extends UICameraComponent {
  
  color[] previewBuffer;
  color[] black;
  
  UITrees() {
    previewBuffer = new int[lx.total];
    black = new int[lx.total];
    for (int i = 0; i < black.length; ++i) {
      black[i] = 0xff000000;
    }
  }
  
  protected void onDraw(UI ui) {
    lights();
    pointLight(0, 0, 80, model.cx, geometry.HEIGHT/2, -10*FEET);

    noStroke();
    fill(#191919);
    beginShape();
    vertex(0, 0, 0);
    vertex(30*FEET, 0, 0);
    vertex(30*FEET, 0, 30*FEET);
    vertex(0, 0, 30*FEET);
    endShape(CLOSE);

    drawTrees(ui);
    drawLights(ui);
  }
  
  private void drawTrees(UI ui) {
    noStroke();
    fill(#333333);
    for (Tree tree : model.trees) {
      pushMatrix();
      translate(tree.x, 0, tree.z);
      rotateY(-tree.ry * PI / 180);
      drawTree(ui);
      popMatrix();
    }
  }
  
  private void drawTree(UI ui) {
    for (int i = 0; i < 4; ++i) {
      for (int y = 1; y < geometry.distances.length; ++y) {
        float beamY = geometry.heights[y];
        float prevY = geometry.heights[y-1];
        float distance = geometry.distances[y];
        float prevDistance = geometry.distances[y-1];
        
        if (y <= geometry.NUM_BEAMS) {
          beginShape();
          vertex(-distance, beamY - geometry.BEAM_WIDTH/2, -distance);
          vertex(-distance, beamY + geometry.BEAM_WIDTH/2, -distance);
          vertex(distance, beamY + geometry.BEAM_WIDTH/2, -distance);
          vertex(distance, beamY - geometry.BEAM_WIDTH/2, -distance);
          endShape(CLOSE);
        }
        
        beginShape();
        vertex(-geometry.BEAM_WIDTH/2, prevY, -prevDistance);
        vertex(geometry.BEAM_WIDTH/2, prevY, -prevDistance);
        vertex(geometry.BEAM_WIDTH/2, beamY, -distance);
        vertex(-geometry.BEAM_WIDTH/2, beamY, -distance);
        endShape(CLOSE);
        
        beginShape();
        vertex(prevDistance-geometry.BEAM_WIDTH/2, prevY, -prevDistance-geometry.BEAM_WIDTH/2);
        vertex(prevDistance+geometry.BEAM_WIDTH/2, prevY, -prevDistance+geometry.BEAM_WIDTH/2);
        vertex(distance+geometry.BEAM_WIDTH/2, beamY, -distance+geometry.BEAM_WIDTH/2);
        vertex(distance-geometry.BEAM_WIDTH/2, beamY, -distance-geometry.BEAM_WIDTH/2);
        endShape(CLOSE);        
      }
      rotateY(PI/2); 
    }    
  }
     
  private void drawLights(UI ui) {
    
    color[] colors;
    boolean isPreviewOn = false;
    for (BooleanParameter previewChannel : previewChannels) {
      isPreviewOn |= previewChannel.isOn();
    }
    if (!isPreviewOn) {
      colors = lx.getColors();
    } else {
      colors = black;
      for (int i = 0; i < NUM_CHANNELS; i++) {
        if (previewChannels[i].isOn()) {
          LXChannel channel = lx.engine.getChannel(i);
          channel.getFaderTransition().blend(colors, channel.getColors(), 1);
          colors = channel.getFaderTransition().getColors();
        }
      }
      for (int i = 0; i < colors.length; ++i) {
        previewBuffer[i] = colors[i];
      }
      colors = previewBuffer;
    }
    noStroke();
    noFill();
    
    if (mappingTool.isEnabled()) {
      Cluster cluster = mappingTool.getCluster();
      JSONObject config = mappingTool.getConfig();
      Tree tree = model.trees.get(config.getInt("treeIndex"));
      
      pushMatrix();
      translate(tree.x, 0, tree.z);
      rotateY(-tree.ry * PI / 180);
      
      // This is some bad duplicated code from Model, hack for now
      int clusterLevel = config.getInt("level");
      int clusterFace = config.getInt("face");
      float clusterOffset = config.getFloat("offset");
      float clusterMountPoint = config.getFloat("mountPoint");
      float clusterSkew = config.getFloat("skew", 0);
      float cry = 0;
      switch (clusterFace) {
        // Could be math, but this way it's readable!
        case FRONT: case FRONT_RIGHT:                  break;
        case RIGHT: case REAR_RIGHT:  cry = HALF_PI;   break;
        case REAR:  case REAR_LEFT:   cry = PI;        break;
        case LEFT:  case FRONT_LEFT:  cry = 3*HALF_PI; break;
      }
      switch (clusterFace) {
        case FRONT_RIGHT:
        case REAR_RIGHT:
        case REAR_LEFT:
        case FRONT_LEFT:
          clusterOffset = 0;
          break;
      }
      rotateY(-cry);
      translate(clusterOffset * geometry.distances[clusterLevel], geometry.heights[clusterLevel] + clusterMountPoint, -geometry.distances[clusterLevel]);
      
      switch (clusterFace) {
        case FRONT_RIGHT:
        case REAR_RIGHT:
        case REAR_LEFT:
        case FRONT_LEFT:
          translate(geometry.distances[clusterLevel], 0, 0);
          rotateY(-QUARTER_PI);
          cry += QUARTER_PI;
          break;
      }
      
      rotateX(-geometry.angleFromAxis(geometry.heights[clusterLevel]));
      rotateZ(-clusterSkew * PI / 180);
      drawCubes(cluster, colors);
      
      popMatrix();
    } else {
      for (Cluster cluster : model.clusters) {
        drawCluster(cluster, colors);
      }
    }
    
    noLights();
  }
  
  void drawCluster(Cluster cluster, color[] colors) {
    pushMatrix();
    translate(cluster.x, cluster.y, cluster.z);
    rotateY(-cluster.ry * PI / 180);
    rotateX(-cluster.rx * PI / 180);
    rotateZ(-cluster.skew * PI / 180);
    drawCubes(cluster, colors);
    popMatrix();
  }
  
  void drawCubes(Cluster cluster, color[] colors) {
    for (Cube cube : cluster.cubes) {
      pushMatrix();
      fill(colors[cube.index]);
      translate(cube.lx, cube.ly, cube.lz);
      rotateY(-cube.ry * PI / 180);
      rotateX(-cube.rx * PI / 180);
      rotateZ(-cube.rz * PI / 180);
      box(cube.size, cube.size, cube.size);
      popMatrix();
    }
  }
}

public class UILoopRecorder extends UIWindow {
  
  private final UILabel slotLabel;
  private final String[] labels = new String[] { "-", "-", "-", "-" };
  
  UILoopRecorder(UI ui) {
    super(ui, "LOOP RECORDER", Trees.this.width-144, Trees.this.height - 152, 140, 148);
    float yPos = TITLE_LABEL_HEIGHT;
    new UIToggleSet(4, yPos, this.width-8, 20)
    .setOptions(new String[] { "A", "B", "C", "D" })
    .setParameter(automationSlot)
    .addToContainer(this);
    yPos += 26;
    
    final UIButton playButton = new UIButton(6, yPos, 40, 20);
    playButton
    .setLabel("PLAY")
    .addToContainer(this);
      
    final UIButton stopButton = new UIButton(6 + (this.width-8)/3, yPos, 40, 20);
    stopButton
    .setMomentary(true)
    .setLabel("STOP")
    .addToContainer(this);
      
    final UIButton armButton = new UIButton(6 + 2*(this.width-8)/3, yPos, 40, 20);
    armButton
    .setLabel("ARM")
    .setActiveColor(#cc3333)
    .addToContainer(this);
    
    yPos += 24;
    final UIButton loopButton = new UIButton(4, yPos, this.width-8, 20);
    loopButton
    .setInactiveLabel("One-shot")
    .setActiveLabel("Looping")
    .addToContainer(this);
    
    yPos += 24;
    slotLabel = new UILabel(4, yPos, this.width-8, 20);
    slotLabel
    .setLabel("-")
    .setAlignment(CENTER, CENTER)
    .setBackgroundColor(#333333)
    .setBorderColor(#666666)
    .addToContainer(this); 
    
    yPos += 24;
    new UIButton(4, yPos, (this.width-12)/2, 20) {
      protected void onToggle(boolean active) {
        if (active) {
          String fileName = labels[automationSlot.getValuei()].equals("-") ? "set.json" : labels[automationSlot.getValuei()]; 
          selectOutput("Save Set",  "saveSet", new File(dataPath(fileName)), UILoopRecorder.this);
        }
      }
    }
    .setMomentary(true)
    .setLabel("Save")
    .addToContainer(this);
    
    new UIButton(this.width - (this.width-12)/2 - 4, yPos, (this.width-12)/2, 20) {
      protected void onToggle(boolean active) {
        if (active) {
          selectInput("Load Set",  "loadSet", new File(dataPath("")), UILoopRecorder.this);
        }
      }
    }
    .setMomentary(true)
    .setLabel("Load")
    .addToContainer(this);
    
    final LXParameterListener listener;
    automationSlot.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXAutomationRecorder auto = automation[automationSlot.getValuei()];
        stopButton.setParameter(automationStop[automationSlot.getValuei()]);
        playButton.setParameter(auto.isRunning);
        armButton.setParameter(auto.armRecord);
        loopButton.setParameter(auto.looping);
        slotLabel.setLabel(labels[automationSlot.getValuei()]);
      }
    });
    listener.onParameterChanged(null);
  }

  public void saveSet(File file) {
    if (file != null) {
      saveJSONArray(automation[automationSlot.getValuei()].toJSON(), file.getPath());
      slotLabel.setLabel(labels[automationSlot.getValuei()] = file.getName());
    }
  }
  
  public void loadSet(File file) {
    if (file != null) {
      JSONArray jsonArr = loadJSONArray(file.getPath());
      automation[automationSlot.getValuei()].loadJSON(jsonArr);
      slotLabel.setLabel(labels[automationSlot.getValuei()] = file.getName());
    }
  }

}

class UIChannelFaders extends UIContext {
  
  final static int SPACER = 30;
  final static int MASTER = 0;
  final static int PADDING = 4;
  final static int BUTTON_HEIGHT = 14;
  final static int FADER_WIDTH = 40;
  final static int WIDTH = SPACER + PADDING + MASTER + (PADDING+FADER_WIDTH)*(NUM_CHANNELS+1);
  final static int HEIGHT = 140;
  
  UIChannelFaders(final UI ui) {
    super(ui, Trees.this.width/2-WIDTH/2, Trees.this.height-HEIGHT-PADDING, WIDTH, HEIGHT);
    setBackgroundColor(#292929);
    setBorderColor(#444444);
    int di = 0;
    final UISlider[] sliders = new UISlider[NUM_CHANNELS];
    final UIButton[] cues = new UIButton[NUM_CHANNELS];
    final UILabel[] labels = new UILabel[NUM_CHANNELS];
    for (int i = 0; i < NUM_CHANNELS; i++) {
      final LXChannel channel = lx.engine.getChannel(i);
      float xPos = PADDING + channel.getIndex()*(PADDING+FADER_WIDTH) + SPACER;
      
      previewChannels[channel.getIndex()] = new BooleanParameter("PRV");
      
      previewChannels[channel.getIndex()].addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          cues[channel.getIndex()].setActive(previewChannels[channel.getIndex()].isOn());
        }
      });
      
      cues[channel.getIndex()] = new UIButton(xPos, PADDING, FADER_WIDTH, BUTTON_HEIGHT) {
        void onToggle(boolean active) {
          previewChannels[channel.getIndex()].setValue(active);
        }
      };
      cues[channel.getIndex()]
      .setActive(previewChannels[channel.getIndex()].isOn())
      .addToContainer(this);
      
      sliders[channel.getIndex()] = new UISlider(UISlider.Direction.VERTICAL, xPos, 1*BUTTON_HEIGHT + 2*PADDING, FADER_WIDTH, this.height - 3*BUTTON_HEIGHT - 5*PADDING) {
        public void onFocus() {
          lx.engine.focusedChannel.setValue(channel.getIndex());
        }
      };
      sliders[channel.getIndex()]
      .setParameter(channel.getFader())
      .addToContainer(this);
            
      labels[channel.getIndex()] = new UILabel(xPos, this.height - 2*PADDING - 2*BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT);
      labels[channel.getIndex()]
      .setLabel(shortPatternName(channel.getActivePattern()))
      .setAlignment(CENTER, CENTER)
      .setColor(#999999)
      .setBackgroundColor(#292929)
      .setBorderColor(#666666)
      .addToContainer(this);
      
      channel.addListener(new LXChannel.AbstractListener() {

        void patternWillChange(LXChannel channel, LXPattern pattern, LXPattern nextPattern) {
          labels[channel.getIndex()].setLabel(shortPatternName(nextPattern));
          labels[channel.getIndex()].setColor(#292929);
          labels[channel.getIndex()].setBackgroundColor(#666699);
        }
        
        void patternDidChange(LXChannel channel, LXPattern pattern) {
          labels[channel.getIndex()].setLabel(shortPatternName(pattern));
          labels[channel.getIndex()].setColor(#999999);
          labels[channel.getIndex()].setBackgroundColor(#292929);
        }
      });
      
    }
    
    float xPos = this.width - FADER_WIDTH - PADDING;
    new UISlider(UISlider.Direction.VERTICAL, xPos, PADDING, FADER_WIDTH, this.height-4*PADDING-2*BUTTON_HEIGHT)
    .setParameter(output.brightness)
    .addToContainer(this);
    
    LXParameterListener listener;
    lx.engine.focusedChannel.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        for (int i = 0; i < sliders.length; ++i) {
          sliders[i].setBackgroundColor((i == focusedChannel()) ? ui.getHighlightColor() : #333333);
        }
      }
    });
    listener.onParameterChanged(lx.engine.focusedChannel);
    
    float labelX = PADDING;
    
    new UILabel(labelX, PADDING+2, 0, 0)
    .setColor(#666666)
    .setLabel("CUE")
    .addToContainer(this);
    
    new UILabel(labelX, 2*PADDING+1*BUTTON_HEIGHT+2, 0, 0)
    .setColor(#666666)
    .setLabel("LEVEL")
    .addToContainer(this);
    
    new UILabel(labelX, this.height - 2*PADDING - 2*BUTTON_HEIGHT + 3, 0, 0)
    .setColor(#666666)
    .setLabel("PTN")
    .addToContainer(this);
    
    new UILabel(labelX, this.height - PADDING - BUTTON_HEIGHT + 3, 0, 0)
    .setColor(#666666)
    .setLabel("CPU")
    .addToContainer(this);
    
    new UILabel(this.width - PADDING - FADER_WIDTH, this.height-2*PADDING-2*BUTTON_HEIGHT, FADER_WIDTH, BUTTON_HEIGHT)
    .setColor(#666666)
    .setAlignment(CENTER, CENTER)
    .setLabel("MASTER")
    .addToContainer(this);
    
    new UIPerfMeters()
    .setPosition(SPACER+PADDING, this.height-PADDING-BUTTON_HEIGHT)
    .addToContainer(this);
    
  }
  
  private String shortPatternName(LXPattern pattern) {
    String simpleName = pattern.getClass().getSimpleName(); 
    return simpleName.substring(0, min(7, simpleName.length()));
  }
  
  class UIPerfMeters extends UIObject {
    
    DampedParameter dampers[] = new DampedParameter[NUM_CHANNELS+1];
    BasicParameter perfs[] = new BasicParameter[NUM_CHANNELS+1];
   
    UIPerfMeters() {
      for (int i = 0; i < NUM_CHANNELS+1; ++i) {
        lx.addModulator((dampers[i] = new DampedParameter(perfs[i] = new BasicParameter("PERF", 0), 3)).start());
      }
    } 
    
    public void onDraw(UI ui, PGraphics pg) {
      for (int i = 0; i < NUM_CHANNELS; i++) {
        LXChannel channel = lx.engine.getChannel(i);
        LXPattern pattern = channel.getActivePattern();
        float goMillis = pattern.timer.runNanos / 1000000.;
        float fps60 = 1000 / 60. / 3.;
        perfs[channel.getIndex()].setValue(constrain((goMillis-1) / fps60, 0, 1));
      }
      float engMillis = lx.engine.timer.runNanos / 1000000.;
      perfs[NUM_CHANNELS].setValue(constrain(engMillis / (1000. / 60.), 0, 1));
        
      for (int i = 0; i < NUM_CHANNELS + 1; ++i) {
        float val = dampers[i].getValuef();
        pg.stroke(#666666);
        pg.fill(#292929);
        pg.rect(i*(PADDING + FADER_WIDTH), 0, FADER_WIDTH-1, BUTTON_HEIGHT-1); 
        pg.fill(lx.hsb(120*(1-val), 50, 80));
        pg.noStroke();
        pg.rect(i*(PADDING + FADER_WIDTH)+1, 1, val * (FADER_WIDTH-2), BUTTON_HEIGHT-2);
      }
      redraw();
    }
  }
}

public class UIMultiDeck extends UIWindow {

  private final static int KNOBS_PER_ROW = 4;
  
  public final static int DEFAULT_WIDTH = 140;
  public final static int DEFAULT_HEIGHT = 258;

  final UIItemList[] patternLists;
  final UIToggleSet[] blendModes;
  final LXChannel.Listener[] lxListeners;
  final UIKnob[] knobs;

  public UIMultiDeck(UI ui) {
    super(ui, "CHANNEL " + (focusedChannel()+1), Trees.this.width - 4 - DEFAULT_WIDTH, Trees.this.height - 156 - DEFAULT_HEIGHT, DEFAULT_WIDTH, DEFAULT_HEIGHT);
    int yp = TITLE_LABEL_HEIGHT;

    patternLists = new UIItemList[NUM_CHANNELS];
    blendModes = new UIToggleSet[NUM_CHANNELS];
    lxListeners = new LXChannel.Listener[patternLists.length];
    for (int i = 0; i < NUM_CHANNELS; i++) {
      LXChannel channel = lx.engine.getChannel(i);
      List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
      for (LXPattern p : channel.getPatterns()) {
        items.add(new PatternScrollItem(channel, p));
      }
      patternLists[channel.getIndex()] = new UIItemList(1, yp, this.width - 2, 100).setItems(items);
      patternLists[channel.getIndex()].setVisible(channel.getIndex() == focusedChannel());
      patternLists[channel.getIndex()].addToContainer(this);      
    }
    
    yp += patternLists[0].getHeight() + 10;
    knobs = new UIKnob[NUM_KNOBS];
    for (int ki = 0; ki < knobs.length; ++ki) {
      knobs[ki] = new UIKnob(5 + 34 * (ki % KNOBS_PER_ROW), yp
        + (ki / KNOBS_PER_ROW) * 48);
      knobs[ki].addToContainer(this);
    }
    
    yp += 100;
    for (int i = 0; i < NUM_CHANNELS; i++) {
      LXChannel channel = lx.engine.getChannel(i);
      blendModes[channel.getIndex()] = new UIToggleSet(4, yp, this.width-8, 18)
      .setOptions(new String[] { "ADD", "MLT", "LITE", "SUBT" })
      .setParameter(getFaderTransition(channel).blendMode)
      .setEvenSpacing();
      blendModes[channel.getIndex()].setVisible(channel.getIndex() == focusedChannel());
      blendModes[channel.getIndex()].addToContainer(this);
    }
     
    for (int i = 0; i < NUM_CHANNELS; i++) {
      LXChannel channel = lx.engine.getChannel(i); 
      lxListeners[channel.getIndex()] = new LXChannel.AbstractListener() {
        public void patternWillChange(LXChannel channel, LXPattern pattern,
            LXPattern nextPattern) {
          patternLists[channel.getIndex()].redraw();
        }

        public void patternDidChange(LXChannel channel, LXPattern pattern) {
          List<LXPattern> patterns = channel.getPatterns();
          for (int i = 0; i < patterns.size(); ++i) {
            if (patterns.get(i) == pattern) {
              patternLists[channel.getIndex()].setFocusIndex(i);
              break;
            }
          }  
          
          patternLists[channel.getIndex()].redraw();
          if (channel.getIndex() == focusedChannel()) {
            int pi = 0;
            for (LXParameter parameter : pattern.getParameters()) {
              if (pi >= knobs.length) {
                break;
              }
              if (parameter instanceof LXListenableNormalizedParameter) {
                knobs[pi++].setParameter((LXListenableNormalizedParameter)parameter);
              }
            }
            while (pi < knobs.length) {
              knobs[pi++].setParameter(null);
            }
          }
        }
      };
      channel.addListener(lxListeners[channel.getIndex()]);
      lxListeners[channel.getIndex()].patternDidChange(channel, channel.getActivePattern());
    }
    
    lx.engine.focusedChannel.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXChannel channel = lx.engine.getChannel(focusedChannel()); 
        
        setTitle("CHANNEL " + (channel.getIndex() + 1));
        redraw();
        
        lxListeners[channel.getIndex()].patternDidChange(channel, channel.getActivePattern());
        
        int pi = 0;
        for (UIItemList patternList : patternLists) {
          patternList.setVisible(pi == focusedChannel());
          ++pi;
        }
        pi = 0;
        for (UIToggleSet blendMode : blendModes) {
          blendMode.setVisible(pi == focusedChannel());
          ++pi;
        }
      }
    });
    
  }
  
  void select() {
    patternLists[focusedChannel()].select();
  }
  
  float amt = 0;
  void knob(int delta) {
    if (delta > 64) {
      delta = delta - 128;
    }
    amt += delta / 4.;
    if (amt > 1) {
      scroll(1);
      amt -= 1;
    } else if (amt < -1) {
      scroll(-1);
      amt += 1;
    }
  }
  
  void selectPattern(int channel, int index) {
    lx.engine.getChannel(channel).goIndex(patternLists[channel].getScrollOffset() + index);
  }
  
  void pagePatterns(int channel) {
    int offset = patternLists[channel].getScrollOffset();
    patternLists[channel].setScrollOffset(offset + 5);
    if (patternLists[channel].getScrollOffset() == offset) {
      patternLists[channel].setScrollOffset(0);
    }
  }
  
  void scroll(int delta) {
    UIItemList list = patternLists[focusedChannel()]; 
    list.setFocusIndex(list.getFocusIndex() + delta);
  } 

  private class PatternScrollItem extends UIItemList.AbstractItem {

    private final LXChannel channel;
    private final LXPattern pattern;

    private final String label;

    PatternScrollItem(LXChannel channel, LXPattern pattern) {
      this.channel = channel;
      this.pattern = pattern;
      this.label = UI.uiClassName(pattern, "Pattern");
    }

    public String getLabel() {
      return this.label;
    }

    public boolean isSelected() {
      return this.channel.getActivePattern() == this.pattern;
    }

    public boolean isPending() {
      return this.channel.getNextPattern() == this.pattern;
    }

    public void onMousePressed() {
      this.channel.goPattern(this.pattern);
    }
  }
}

class UIEffects extends UIWindow {
  
  final int KNOBS_PER_ROW = 4;
  
  UIEffects(UI ui, LXListenableNormalizedParameter[] effectKnobParameters) {
    super(ui, "MASTER EFFECTS", Trees.this.width-144, 110, 140, 120);
    
    int yp = TITLE_LABEL_HEIGHT;
    for (int ki = 0; ki < 8; ++ki) {
      new UIKnob(5 + 34 * (ki % KNOBS_PER_ROW), yp + (ki / KNOBS_PER_ROW) * 48)
      .setParameter(effectKnobParameters[ki])
      .addToContainer(this);
    }
    yp += 98;
    
  } 
  
}


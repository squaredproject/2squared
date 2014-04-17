import heronarts.lx.ui.component.*;
import heronarts.lx.*;
import heronarts.lx.effect.*;
import heronarts.lx.midi.*;
import heronarts.lx.model.*;
import heronarts.lx.output.*;
import heronarts.lx.parameter.*;
import heronarts.lx.pattern.*;
import heronarts.lx.transform.*;
import heronarts.lx.transition.*;
import heronarts.lx.midi.*;
import heronarts.lx.modulator.*;
import heronarts.lx.ui.*;
import heronarts.lx.ui.control.*;

import ddf.minim.*;
import processing.opengl.*;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;

final static int INCHES = 1;
final static int FEET = 12 * INCHES;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static int A = 0;
final static int B = 1;

final static float CHAIN = -12;
final static float BOLT = 22;

final static int FRONT = 0;
final static int RIGHT = 1;
final static int REAR = 2;
final static int LEFT = 3;
final static int FRONT_RIGHT = 4;
final static int REAR_RIGHT = 5;
final static int REAR_LEFT = 6;
final static int FRONT_LEFT = 7;

final static int NUM_CHANNELS = 8;
final static int NUM_KNOBS = 8;
final static int NUM_AUTOMATION = 4;

/**
 * This defines the positions of the trees, which are
 * x (left to right), z (front to back), and rotation
 * in degrees.
 */
final static float[][] TREE_POSITIONS = {
  /*  X-pos    Y-pos    Rot  */
  {  15*FEET,  15*FEET,   0  },
  {  90*FEET,  15*FEET, -45  }
};

final static String CLUSTER_CONFIG_FILE = "data/clusters.json";

static JSONArray clusterConfig;
static Geometry geometry = new Geometry();

Model model;
LX lx;
LXDatagramOutput output;
LXDatagram[] datagrams;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
BlurEffect blurEffect;
ColorEffect colorEffect;
BPMTool bpmTool;
MappingTool mappingTool;
LXListenableNormalizedParameter[] effectKnobParameters;
BooleanParameter[] effectButtonParameters;
LXAutomationRecorder[] automation = new LXAutomationRecorder[NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", NUM_AUTOMATION);
MidiEngine midiEngine;
TSDrumpad drumpad;
TSKeyboard keyboard;

LXPattern[] patterns(LX lx) {
  LXPattern[] patterns = new LXPattern[] {
    new SolidColor(lx),
    new Twister(lx),
    new MarkLottor(lx),
    new DoubleHelix(lx),
    new SparkleHelix(lx),
    new Lightning(lx),
    new SparkleTakeOver(lx),
    new MultiSine(lx),
    new Ripple(lx),
    new SeeSaw(lx),
    new SweepPattern(lx),
    new IceCrystals(lx),
    new ColoredLeaves(lx),
    new Stripes(lx),
    new SyphonPattern(lx, this),
    new TestPattern(lx).setEligible(false),
    new TestCluster(lx).setEligible(false),
    new OrderTest(lx),
    new ClusterLineTest(lx),
    new Zebra(lx),
    new AcidTrip(lx),
    new Pulley(lx),
    new Springs(lx),
    new Lattice(lx),
    new Fire(lx),
    new Bubbles(lx),
    new BouncyBalls(lx),
    new Fumes(lx),
    new Voronoi(lx),
    new Wisps(lx),
    new Explosions(lx),
    new BassSlam(lx),
    new Rain(lx),
    new Fade(lx),
    new Strobe(lx),
    new Twinkle(lx),
    new VerticalSweep(lx),
    new RandomColor(lx),
    new RandomColorAll(lx),
  };
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  for (LXPattern p : patterns) {
    p.setTransition(t);
  }
  return patterns;
}

void setup() {
  size(960, 600, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  clusterConfig = loadJSONArray(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model();
  
  // saveJSONArray(clusterConfig, CLUSTER_CONFIG_FILE);
    
  lx = new LX(this, model);
  lx.setPatterns(patterns(lx));
  for (int i = 1; i < NUM_CHANNELS - (isMPK25Connected() ? 1 : 0); ++i) {
    lx.engine.addDeck(patterns(lx));
  }
  
  if (isMPK25Connected()) {
    keyboard = new TSKeyboard();
    keyboard.configure(lx);
  }
  
  for (LXDeck deck : lx.engine.getDecks()) {
    deck.goIndex(deck.index);
    deck.setFaderTransition(new TreesTransition(lx, deck));
  }
  
  // Effects
  lx.addEffect(blurEffect = new BlurEffect(lx));
  lx.addEffect(colorEffect = new ColorEffect(lx));
  lx.addEffect(mappingTool = new MappingTool(lx));
  GhostEffect ghostEffect = new GhostEffect(lx);
  lx.addEffect(ghostEffect);
  
  effectKnobParameters = new LXListenableNormalizedParameter[] {
      colorEffect.hueShift,
      colorEffect.rainbow,
      colorEffect.mono,
      colorEffect.desaturation,
      colorEffect.sharp,
      colorEffect.soft,
      blurEffect.amount,
      ghostEffect.amount,
  };
  
  effectButtonParameters = new BooleanParameter[] {
    new BooleanParameter("-", false),
    new BooleanParameter("-", false),
    new BooleanParameter("-", false),
    new BooleanParameter("-", false)
  };
  
  bpmTool = new BPMTool();
  bpmTool.AddBPMListener(lx.getPatterns());

  // Automation recorders
  for (int i = 0; i < automation.length; ++i) {
    final int ii = i;
    automation[i] = new LXAutomationRecorder(lx.engine);
    lx.addModulator(automation[i]);
    automationStop[i] = new BooleanParameter("STOP", false);
    automationStop[i].addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        if (parameter.getValue() > 0) {
          automation[ii].reset();
          automation[ii].armRecord.setValue(false);
        }
      }
    });
  }

  // Output stage
  try {
    output = new LXDatagramOutput(lx);
    datagrams = new LXDatagram[model.clusters.size()];
    int ci = 0;
    for (Cluster cluster : model.clusters) {
      output.addDatagram(datagrams[ci++] = clusterDatagram(cluster).setAddress(cluster.ipAddress));
    }
    output.enabled.setValue(false);
    lx.addOutput(output);
  } catch (Exception x) {
    println(x);
  }
  
  // UI initialization
  lx.ui.addLayer(new UICameraLayer(lx.ui) {
      protected void beforeDraw() {
        hint(ENABLE_DEPTH_TEST);
        pushMatrix();
        translate(0, 12*FEET, 0);
      }
      protected void afterDraw() {
        popMatrix();
        hint(DISABLE_DEPTH_TEST);
      }  
    }
    .setRadius(90*FEET)
    .setCenter(model.cx, model.cy, model.cz)
    .addComponent(new UITrees())
  );
  lx.ui.addLayer(new UIOutput(lx.ui, 4, 4));
  lx.ui.addLayer(new UIMapping(lx.ui));
  lx.ui.addLayer(uiFaders = new UIChannelFaders(lx.ui));
  lx.ui.addLayer(new UIEffects(lx.ui));
  lx.ui.addLayer(uiDeck = new UIMultiDeck(lx.ui));
  lx.ui.addLayer(new UILoopRecorder(lx.ui));
  lx.ui.addLayer(new UIMasterBpm(lx.ui, Trees.this.width-144, 4));
  
  // MIDI control
  midiEngine = new MidiEngine();
  if (midiEngine.mpk25 != null) {
    // Drumpad
    drumpad = new TSDrumpad();
    drumpad.configure(lx);
    midiEngine.mpk25.setDrumpad(drumpad);

    midiEngine.mpk25.setKeyboard(keyboard);
  }
  
  // bad code I know
  // (shouldn't mess with engine internals)
  // maybe need a way to specify a deck shouldn't be focused?
  // essentially this lets us have extra decks for the drumpad
  // patterns without letting them be assigned to channels
  // -kf
  lx.engine.focusedDeck.setRange(NUM_CHANNELS);
  
  // Engine threading
  lx.engine.framesPerSecond.setValue(60);  
  lx.engine.setThreaded(true);
}
  
void draw() {
  background(#222222);
}

TreesTransition getFaderTransition(LXDeck deck) {
  return (TreesTransition) deck.getFaderTransition();
}

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
    vertex(105*FEET, 0, 0);
    vertex(105*FEET, 0, 30*FEET);
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
          LXDeck deck = lx.engine.getDeck(i);
          deck.getFaderTransition().blend(colors, deck.getColors(), 1, 0);
          colors = deck.getFaderTransition().getColors();
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

class UIOutput extends UIWindow {
  UIOutput(UI ui, float x, float y) {
    super(ui, "LIVE OUTPUT", x, y, 140, 72 + 239);
    float yPos = UIWindow.TITLE_LABEL_HEIGHT - 2;
    new UIButton(4, yPos, width-8, 20)
      .setParameter(output.enabled)
      .setActiveLabel("Enabled")
      .setInactiveLabel("Disabled")
      .addToContainer(this);
    yPos += 28;
    
    List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
    for (LXDatagram datagram : datagrams) {
      items.add(new DatagramItem(datagram));
    }
    new UIItemList(1, yPos, width-2, 260)
    .setItems(items)
    .setBackgroundColor(#ff0000)
    .addToContainer(this);
  }
  
  class DatagramItem extends UIItemList.AbstractItem {
    
    final LXDatagram datagram;
    
    DatagramItem(LXDatagram datagram) {
      this.datagram = datagram;
      datagram.enabled.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          redraw();
        }
      });
    }
    
    String getLabel() {
      return datagram.getAddress().toString();
    }
    
    boolean isSelected() {
      return datagram.enabled.isOn();
    }
    
    void onMousePressed() {
      datagram.enabled.toggle();
    }
  }
}

class UILoopRecorder extends UIWindow {
  UILoopRecorder(UI ui) {
    super(ui, "LOOP RECORDER", Trees.this.width-144, Trees.this.height - 104, 140, 100);
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
    
    final LXParameterListener listener;
    automationSlot.addListener(listener = new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        LXAutomationRecorder auto = automation[automationSlot.getValuei()];
        stopButton.setParameter(automationStop[automationSlot.getValuei()]);
        playButton.setParameter(auto.isRunning);
        armButton.setParameter(auto.armRecord);
        loopButton.setParameter(auto.looping);
      }
    });
    listener.onParameterChanged(null);
  }
}

class TreesTransition extends LXTransition {
  
  private final LXDeck deck;
  
  public final DiscreteParameter blendMode = new DiscreteParameter("MODE", 4);
  public final BooleanParameter left = new BooleanParameter("LEFT", true);
  public final BooleanParameter right = new BooleanParameter("RIGHT", true);
  
  private final DampedParameter leftLevel = new DampedParameter(left, 2);
  private final DampedParameter rightLevel = new DampedParameter(right, 2);
 
  private int blendType = ADD;
  
  private final color[] scaleBuffer = new color[lx.total];
  
  TreesTransition(LX lx, LXDeck deck) {
    super(lx);
    addParameter(blendMode);
    addParameter(left);
    addParameter(right);
    
    addModulator(leftLevel.start());
    addModulator(rightLevel.start());
    this.deck = deck;
    blendMode.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        switch (blendMode.getValuei()) {
        case 0: blendType = ADD; break;
        case 1: blendType = MULTIPLY; break;
        case 2: blendType = LIGHTEST; break;
        case 3: blendType = SUBTRACT; break;
        }
      }
    });
  }
  
  protected void computeBlend(int[] c1, int[] c2, double progress) {
    for (Tree tree : model.trees) {
      float level = ((tree.index == 0) ? leftLevel : rightLevel).getValuef();
      float amount = (float) (progress*level);
      if (amount == 0) {
        for (LXPoint p : tree.points) {
          colors[p.index] = c1[p.index];
        }
      } else if (amount == 1) {
        for (LXPoint p : tree.points) {
          int color2 = blendType == SUBTRACT ? LX.hsb(0, 0, LX.b(c2[p.index])) : c2[p.index]; 
          colors[p.index] = this.lx.applet.blendColor(c1[p.index], color2, this.blendType);
        }
      } else {
        for (LXPoint p : tree.points) {
          int color2 = blendType == SUBTRACT ? LX.hsb(0, 0, LX.b(c2[p.index])) : c2[p.index];
          this.colors[p.index] = this.lx.applet.lerpColor(c1[p.index],
            this.lx.applet.blendColor(c1[p.index], color2, this.blendType),
            amount, PConstants.RGB);
        }
      }
    }
  }
}

void keyPressed() {
  switch (key) {
    case 'a':
      if (datagrams.length > 0) {
        boolean toEnable = !datagrams[0].enabled.isOn();
        for (LXDatagram datagram : datagrams) {
          datagram.enabled.setValue(toEnable);
        }
      }
      break;
  }
}


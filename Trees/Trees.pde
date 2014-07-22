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
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

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
  {  15*FEET,  15*FEET,   0  }
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
GhostEffect ghostEffect;
ScrambleEffect scrambleEffect;
BPMTool bpmTool;
MappingTool mappingTool;
LXAutomationRecorder[] automation = new LXAutomationRecorder[NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", NUM_AUTOMATION);
MidiEngine midiEngine;
TSDrumpad drumpad;
TSKeyboard keyboard;
Minim minim;

LXPattern[] patterns(LX lx) {
  ArrayList <LXPattern> patterns = new ArrayList<LXPattern>();
  patterns.add(new SolidColor(lx));
  patterns.add(new Twister(lx));
  patterns.add(new MarkLottor(lx));
  patterns.add(new DoubleHelix(lx));
  patterns.add(new SparkleHelix(lx));
  patterns.add(new Lightning(lx));
  patterns.add(new SparkleTakeOver(lx));
  patterns.add(new MultiSine(lx));
  patterns.add(new Ripple(lx));
  patterns.add(new SeeSaw(lx));
  patterns.add(new SweepPattern(lx));
  patterns.add(new IceCrystals(lx));
  patterns.add(new ColoredLeaves(lx));
  patterns.add(new Stripes(lx));
  try {
    LXPattern syphon = new SyphonPattern(lx, this);
    patterns.add(syphon);
  } catch (Throwable e) {
    ;
  }
  // patterns.add(new TestPattern(lx).setEligible(false));
  // patterns.add(new TestCluster(lx).setEligible(false));
  // patterns.add(new OrderTest(lx));
  // patterns.add(new ClusterLineTest(lx));
  // patterns.add(new Zebra(lx));
  patterns.add(new AcidTrip(lx));
  // patterns.add(new Pulley(lx)); // broken
  patterns.add(new Springs(lx));
  patterns.add(new Lattice(lx));
  patterns.add(new Fire(lx));
  patterns.add(new FirefliesExp(lx));
  patterns.add(new Fumes(lx));
  patterns.add(new Voronoi(lx));
  patterns.add(new Bubbles(lx));
  
  patterns.add(new Wisps(lx));
  patterns.add(new Explosions(lx));
  patterns.add(new BassSlam(lx));
  patterns.add(new Rain(lx));
  patterns.add(new Fade(lx));
  patterns.add(new Strobe(lx));
  patterns.add(new Twinkle(lx));
  patterns.add(new VerticalSweep(lx));
  patterns.add(new RandomColor(lx));
  patterns.add(new RandomColorAll(lx));
  patterns.add(new Pixels(lx));
  patterns.add(new Wedges(lx));
  patterns.add(new Parallax(lx));
  patterns.add(new LowEQ(lx));
  patterns.add(new MidEQ(lx));
  patterns.add(new HighEQ(lx));

  LXPattern[] l_patterns = patterns.toArray(new LXPattern[patterns.size()]);
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  for (LXPattern p : l_patterns) {
    p.setTransition(t);
  }
  return l_patterns;
}

void setup() {
  size(1024, 680, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  clusterConfig = loadJSONArray(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model();
  
  minim = new Minim(this);
  
  lx = new LX(this, model);
  lx.setPatterns(patterns(lx));
  for (int i = 1; i < NUM_CHANNELS - (isMPK25Connected() ? 1 : 0); ++i) {
    lx.engine.addChannel(patterns(lx));
  }
  
  if (isMPK25Connected()) {
    keyboard = new TSKeyboard();
    keyboard.configure(lx);
  }
  
  for (LXChannel channel : lx.engine.getChannels()) {
    channel.goIndex(channel.getIndex());
    channel.setFaderTransition(new TreesTransition(lx, channel));
  }
  
  // Effects
  lx.addEffect(blurEffect = new BlurEffect(lx));
  lx.addEffect(colorEffect = new ColorEffect(lx));
  lx.addEffect(ghostEffect = new GhostEffect(lx));
  lx.addEffect(scrambleEffect = new ScrambleEffect(lx));
  lx.addEffect(mappingTool = new MappingTool(lx));
  
  LXListenableNormalizedParameter[] effectKnobParameters = new LXListenableNormalizedParameter[] {
      colorEffect.hueShift,
      colorEffect.rainbow,
      colorEffect.mono,
      colorEffect.desaturation,
      colorEffect.sharp,
      blurEffect.amount,
      ghostEffect.amount,
      scrambleEffect.amount,
  };
  
  bpmTool = new BPMTool(lx, effectKnobParameters);

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
    .setTheta(30*PI/180)
    .setPhi(10*PI/180)
    .addComponent(new UITrees())
  );
  lx.ui.addLayer(new UIOutput(lx.ui, 4, 4));
  lx.ui.addLayer(new UIMapping(lx.ui));
  lx.ui.addLayer(uiFaders = new UIChannelFaders(lx.ui));
  lx.ui.addLayer(new UIEffects(lx.ui, effectKnobParameters));
  lx.ui.addLayer(uiDeck = new UIMultiDeck(lx.ui));
  lx.ui.addLayer(new UILoopRecorder(lx.ui));
  lx.ui.addLayer(new UIMasterBpm(lx.ui, Trees.this.width-144, 4, bpmTool));
  
  // MIDI control
  midiEngine = new MidiEngine(effectKnobParameters);
  if (midiEngine.mpk25 != null) {
    // Drumpad
    drumpad = new TSDrumpad();
    drumpad.configure(lx);
    midiEngine.mpk25.setDrumpad(drumpad);

    midiEngine.mpk25.setKeyboard(keyboard);
  }
  
  configureNFC();
  
  // bad code I know
  // (shouldn't mess with engine internals)
  // maybe need a way to specify a deck shouldn't be focused?
  // essentially this lets us have extra decks for the drumpad
  // patterns without letting them be assigned to channels
  // -kf
  lx.engine.focusedChannel.setRange(NUM_CHANNELS);
  
  // Engine threading
  lx.engine.framesPerSecond.setValue(60);  
  lx.engine.setThreaded(true);
}

void draw() {
  background(#222222);
}

TreesTransition getFaderTransition(LXChannel channel) {
  return (TreesTransition) channel.getFaderTransition();
}

class TreesTransition extends LXTransition {
  
  private final LXChannel channel;
  
  public final DiscreteParameter blendMode = new DiscreteParameter("MODE", 4);
  public final BooleanParameter left = new BooleanParameter("LEFT", true);
  public final BooleanParameter right = new BooleanParameter("RIGHT", true);
  
  private final DampedParameter leftLevel = new DampedParameter(left, 2);
  private final DampedParameter rightLevel = new DampedParameter(right, 2);
 
  private int blendType = ADD;
  
  private final color[] scaleBuffer = new color[lx.total];
  
  TreesTransition(LX lx, LXChannel channel) {
    super(lx);
    addParameter(blendMode);
    addParameter(left);
    addParameter(right);
    
    addModulator(leftLevel.start());
    addModulator(rightLevel.start());
    this.channel = channel;
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


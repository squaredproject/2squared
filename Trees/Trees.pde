import heronarts.lx.*;
import heronarts.lx.audio.*;
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

import heronarts.p2lx.*;
import heronarts.p2lx.ui.*;
import heronarts.p2lx.ui.component.*;
import heronarts.p2lx.ui.control.*;

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

final static float CHAIN = -12*INCHES;
final static float BOLT = 22*INCHES;

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

LXPattern[] getPatternListForChannels() {
  ArrayList<LXPattern> patterns = new ArrayList<LXPattern>();
  // patterns.add(new OrderTest(lx));
  
  // Add patterns here.
  // The order here is the order it shows up in the patterns list
  patterns.add(new Twister(lx));
  patterns.add(new CandyCloud(lx));
  patterns.add(new MarkLottor(lx));
  // patterns.add(new DoubleHelix(lx));
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
  patterns.add(new SolidColor(lx));
  try { patterns.add(new SyphonPattern(lx, this)); } catch (Throwable e) {}
  patterns.add(new AcidTrip(lx));
  patterns.add(new Springs(lx));
  patterns.add(new Lattice(lx));
  patterns.add(new Fire(lx));
  patterns.add(new Fireflies(lx));
  patterns.add(new Fumes(lx));
  patterns.add(new Voronoi(lx));
  patterns.add(new Cells(lx));
  patterns.add(new Bubbles(lx));
  patterns.add(new Pulleys(lx));

  patterns.add(new Wisps(lx));
  patterns.add(new Explosions(lx));
  patterns.add(new BassSlam(lx));
  patterns.add(new Rain(lx));
  patterns.add(new Fade(lx));
  patterns.add(new Strobe(lx));
  patterns.add(new Twinkle(lx));
  patterns.add(new VerticalSweep(lx));
  patterns.add(new RandomColor(lx));
  patterns.add(new ColorStrobe(lx));
  patterns.add(new Pixels(lx));
  patterns.add(new Wedges(lx));
  patterns.add(new Parallax(lx));
  patterns.add(new LowEQ(lx));
  patterns.add(new MidEQ(lx));
  patterns.add(new HighEQ(lx));
  patterns.add(new GalaxyCloud(lx));

  patterns.add(new CameraWrap(lx));

  for (LXPattern pattern : patterns) {
    LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
    pattern.setTransition(t);
  }

  return patterns.toArray(new LXPattern[patterns.size()]);
}

void registerPatternTriggerables() {
  // The 2nd parameter is the NFC tag serial number
  // Specify a blank string to only add it to the apc40 drumpad
  // The 3rd parameter is which row of the apc40 drumpad to add it to.
  // defaults to the 3rd row
  // the row parameter is zero indexed

  registerPattern(new Twister(lx), "");
  registerPattern(new MarkLottor(lx), "");
  registerPattern(new Ripple(lx), "");
  registerPattern(new Stripes(lx), "");
  registerPattern(new Lattice(lx), "");
  registerPattern(new Fumes(lx), "");
  registerPattern(new Voronoi(lx), "");
  registerPattern(new CandyCloud(lx), "");
  registerPattern(new GalaxyCloud(lx), "");

  registerPattern(new ColorStrobe(lx), "", 3);
  registerPattern(new Explosions(lx, 20), "", 3);
  registerPattern(new Strobe(lx), "", 3);
  
  registerPattern(new IceCrystals(lx), "", 5);
  registerPattern(new Fire(lx), "", 5);
  
  // registerPattern(new DoubleHelix(lx), "");
  registerPattern(new AcidTrip(lx), "");

  registerPattern(new Wisps(lx, 1, 60, 50, 270, 20, 3.5, 10), ""); // downward yellow wisp
  registerPattern(new Wisps(lx, 1, 210, 100, 90, 130, 3.5, 10), ""); // multidirection colorful wisps
  registerPattern(new Wisps(lx, 30, 210, 100, 90, 20, 3.5, 10), ""); // colorful wisp storm
  registerPattern(new Wisps(lx, 3, 210, 10, 270, 0, 3.5, 10), ""); // rain storm of wisps
  registerPattern(new Wisps(lx, 35, 210, 180, 180, 15, 2, 15), ""); // twister of wisps
}

void registerOneShotTriggerables() {
  registerOneShot(new Pulleys(lx), "");
  registerOneShot(new StrobeOneshot(lx), "");
  registerOneShot(new BassSlam(lx), "");

  registerOneShot(new Fireflies(lx), "", 5);
  registerOneShot(new Bubbles(lx), "", 5);
  registerOneShot(new Lightning(lx), "", 5);
  registerOneShot(new Wisps(lx), "", 5);
  registerOneShot(new Explosions(lx), "", 5);
}

void registerEffectTriggerables() {
  BlurEffect blurEffect = new BlurEffect(lx);
  ColorEffect colorEffect = new ColorEffect(lx);
  GhostEffect ghostEffect = new GhostEffect(lx);
  ScrambleEffect scrambleEffect = new ScrambleEffect(lx);
  StaticEffect staticEffect = new StaticEffect(lx);
  RotationEffect rotationEffect = new RotationEffect(lx);
  SpinEffect spinEffect = new SpinEffect(lx);
  SpeedEffect speedEffect = new SpeedEffect(lx);
  ColorStrobeTextureEffect colorStrobeTextureEffect = new ColorStrobeTextureEffect(lx);
  FadeTextureEffect fadeTextureEffect = new FadeTextureEffect(lx);
  AcidTripTextureEffect acidTripTextureEffect = new AcidTripTextureEffect(lx);
  CandyTextureEffect candyTextureEffect = new CandyTextureEffect(lx);
  CandyCloudTextureEffect candyCloudTextureEffect = new CandyCloudTextureEffect(lx);

  lx.addEffect(blurEffect);
  lx.addEffect(colorEffect);
  lx.addEffect(ghostEffect);
  lx.addEffect(scrambleEffect);
  lx.addEffect(staticEffect);
  lx.addEffect(rotationEffect);
  lx.addEffect(spinEffect);
  lx.addEffect(speedEffect);
  lx.addEffect(colorStrobeTextureEffect);
  lx.addEffect(fadeTextureEffect);
  lx.addEffect(acidTripTextureEffect);
  lx.addEffect(candyTextureEffect);
  lx.addEffect(candyCloudTextureEffect);

  registerEffectControlParameter(speedEffect.speed, "", 1, 0.4);
  registerEffectControlParameter(speedEffect.speed, "", 1, 5);
  registerEffectControlParameter(colorEffect.rainbow, "");
  registerEffectControlParameter(colorEffect.mono, "");
  registerEffectControlParameter(colorEffect.desaturation, "04346762312c80");
  registerEffectControlParameter(colorEffect.sharp, "");
  registerEffectControlParameter(blurEffect.amount, "", 0.65);
  registerEffectControlParameter(spinEffect.spin, "", 0.65);
  registerEffectControlParameter(ghostEffect.amount, "", 0, 0.16, 1);
  registerEffectControlParameter(scrambleEffect.amount, "", 0, 1, 1);
  registerEffectControlParameter(colorStrobeTextureEffect.amount, "", 0, 1, 1);
  registerEffectControlParameter(fadeTextureEffect.amount, "", 0, 1, 1);
  registerEffectControlParameter(acidTripTextureEffect.amount, "", 0, 1, 1);
  registerEffectControlParameter(candyCloudTextureEffect.amount, "", 0, 1, 1);
  registerEffectControlParameter(staticEffect.amount, "", 0, .5, 1);
  registerEffectControlParameter(candyTextureEffect.amount, "", 0, 1, 5);

  effectKnobParameters = new LXListenableNormalizedParameter[] {
    colorEffect.hueShift,
    colorEffect.mono,
    colorEffect.desaturation,
    colorEffect.sharp,
    blurEffect.amount,
    speedEffect.speed,
    spinEffect.spin,
    candyCloudTextureEffect.amount
  };
}

VisualType[] readerPatternTypeRestrictions() {
  return new VisualType[] {
    VisualType.Pattern,
    VisualType.Effect,
    VisualType.Effect,
    VisualType.Effect,
    VisualType.OneShot,
    VisualType.OneShot,
    VisualType.OneShot,
    VisualType.Pattern,
    VisualType.Pattern,
    VisualType.Pattern
  };
}

static JSONArray clusterConfig;
static Geometry geometry = new Geometry();

Model model;
P2LX lx;
LXDatagramOutput output;
LXDatagram[] datagrams;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
final BasicParameter drumpadVelocity = new BasicParameter("DVEL", 1);
BPMTool bpmTool;
MappingTool mappingTool;
LXAutomationRecorder[] automation = new LXAutomationRecorder[NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", NUM_AUTOMATION);
LXListenableNormalizedParameter[] effectKnobParameters;
MidiEngine midiEngine;
TSDrumpad apc40Drumpad;
NFCEngine nfcEngine;
SpeedIndependentContainer speedIndependentContainer;

void setup() {
  size(1148, 720, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  clusterConfig = loadJSONArray(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model();
  
  lx = new P2LX(this, model);
  lx.engine.addLoopTask(speedIndependentContainer = new SpeedIndependentContainer(lx));
  lx.engine.addParameter(drumpadVelocity);

  configureChannels();

  configureNFC();

  // uncomment this to allow any nfc reader to read any cube
  // nfcEngine.disableVisualTypeRestrictions = false;

  configureTriggerables();

  lx.addEffect(mappingTool = new MappingTool(lx));
  lx.engine.addLoopTask(new ModelTransformTask());

  configureBMPTool();

  configureAutomation();

  configureExternalOutput();
  // configureFadeCandyOutput();

  configureUI();

  configureMIDI();
  
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

/* configureChannels */

void configureChannels() {
  lx.setPatterns(getPatternListForChannels());
  for (int i = 1; i < NUM_CHANNELS; ++i) {
    lx.engine.addChannel(getPatternListForChannels());
  }
  
  for (LXChannel channel : lx.engine.getChannels()) {
    channel.goIndex(channel.getIndex());
    channel.setFaderTransition(new TreesTransition(lx, channel));
  }
}

void registerOneShot(TSPattern pattern, String nfcSerialNumber) {
  registerOneShot(pattern, nfcSerialNumber, 4);
}

void registerOneShot(TSPattern pattern, String nfcSerialNumber, int apc40DrumpadRow) {
  registerVisual(pattern, nfcSerialNumber, apc40DrumpadRow, VisualType.OneShot);
}

void registerPattern(TSPattern pattern, String nfcSerialNumber) {
  registerPattern(pattern, nfcSerialNumber, 2);
}

void registerPattern(TSPattern pattern, String nfcSerialNumber, int apc40DrumpadRow) {
  registerVisual(pattern, nfcSerialNumber, apc40DrumpadRow, VisualType.Pattern);
}

void registerVisual(TSPattern pattern, String nfcSerialNumber, int apc40DrumpadRow, VisualType visualType) {
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  pattern.setTransition(t);

  Triggerable triggerable = configurePatternAsTriggerable(pattern);
  nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, visualType);
  apc40DrumpadTriggerablesLists[apc40DrumpadRow].add(triggerable);
}

Triggerable configurePatternAsTriggerable(TSPattern pattern) {
  LXChannel channel = lx.engine.addChannel(new TSPattern[] { pattern });
  channel.setFaderTransition(new TreesTransition(lx, channel));

  pattern.onTriggerableModeEnabled();
  return pattern.getTriggerable();
}

/* configureEffects */

void registerEffect(LXEffect effect, String nfcSerialNumber) {
  if (effect instanceof Triggerable) {
    Triggerable triggerable = (Triggerable)effect;
    nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect);
    apc40DrumpadTriggerablesLists[0].add(triggerable);
  }
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber) {
  registerEffectControlParameter(parameter, nfcSerialNumber, 0, 1, 0);
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber, double onValue) {
  registerEffectControlParameter(parameter, nfcSerialNumber, 0, onValue, 0);
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber, double offValue, double onValue) {
  registerEffectControlParameter(parameter, nfcSerialNumber, offValue, onValue, 0);
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber, double offValue, double onValue, int row) {
  ParameterTriggerableAdapter triggerable = new ParameterTriggerableAdapter(parameter, offValue, onValue);
  nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect);
  apc40DrumpadTriggerablesLists[row].add(triggerable);
}

/* configureBMPTool */

void configureBMPTool() {
  bpmTool = new BPMTool(lx, effectKnobParameters);
}

/* configureAutomation */

void configureAutomation() {
  // Example automation message to change master fader
  // {
  //   "message": "master/0.5",
  //   "event": "MESSAGE",
  //   "millis": 0
  // },
  lx.engine.addMessageListener(new LXEngine.MessageListener() {
    public void onMessage(LXEngine engine, String message) {
      if (message.length() > 8 && message.substring(0, 7).equals("master/")) {
        double value = Double.parseDouble(message.substring(7));
        output.brightness.setValue(value);
      }
    }
  });

  // Automation recorders
  for (int i = 0; i < automation.length; ++i) {
    final int ii = i;
    automation[i] = new LXAutomationRecorder(lx.engine);
    lx.engine.addLoopTask(automation[i]);
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
}

/* configureTriggerables */

ArrayList<Triggerable>[] apc40DrumpadTriggerablesLists;
Triggerable[][] apc40DrumpadTriggerables;

void configureTriggerables() {
  apc40DrumpadTriggerablesLists = new ArrayList[] {
    new ArrayList<Triggerable>(),
    new ArrayList<Triggerable>(),
    new ArrayList<Triggerable>(),
    new ArrayList<Triggerable>(),
    new ArrayList<Triggerable>(),
    new ArrayList<Triggerable>()
  };

  registerPatternTriggerables();
  registerOneShotTriggerables();
  registerEffectTriggerables();

  apc40DrumpadTriggerables = new Triggerable[apc40DrumpadTriggerablesLists.length][];
  for (int i = 0; i < apc40DrumpadTriggerablesLists.length; i++) {
    ArrayList<Triggerable> triggerablesList= apc40DrumpadTriggerablesLists[i];
    apc40DrumpadTriggerables[i] = triggerablesList.toArray(new Triggerable[triggerablesList.size()]);
  }
  apc40DrumpadTriggerablesLists = null;
}

/* configureMIDI */

void configureMIDI() {
  apc40Drumpad = new TSDrumpad();
  apc40Drumpad.triggerables = apc40DrumpadTriggerables;

  // MIDI control
  midiEngine = new MidiEngine(effectKnobParameters);
}

/* configureNFC */

void configureNFC() {
  nfcEngine = new NFCEngine(lx);
  nfcEngine.start();

  nfcEngine.registerReaderPatternTypeRestrictions(Arrays.asList(readerPatternTypeRestrictions()));
}

/* configureUI */

void configureUI() {
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
}

/* configureExternalOutput */

void configureExternalOutput() {
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
}

/* configureFadeCandyOutput */

void configureFadeCandyOutput() {
  int[] clusterOrdering = new int[] { 0, 1, 2, 3, 4, 5, 8, 7, 9, 10, 11, 12, 13, 15, 14, 6 };
  int numCubesInCluster = clusterOrdering.length;
  int numClusters = 48;
  int[] pixelOrder = new int[numClusters * numCubesInCluster];
  for (int cluster = 0; cluster < numClusters; cluster++) {
    for (int cube = 0; cube < numCubesInCluster; cube++) {
      pixelOrder[cluster * numCubesInCluster + cube] = cluster * numCubesInCluster + clusterOrdering[cube];
    }
  }
  try {
    FadecandyOutput fadecandyOutput = new FadecandyOutput(lx, "127.0.0.1", 7890, pixelOrder);
    lx.addOutput(fadecandyOutput);
  } catch (Exception e) {
    println(e);
  }
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
 
  private LXColor.Blend blendType = LXColor.Blend.ADD;
    
  TreesTransition(LX lx, LXChannel channel) {
    super(lx);
    addParameter(blendMode);
    
    this.channel = channel;
    blendMode.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        switch (blendMode.getValuei()) {
        case 0: blendType = LXColor.Blend.ADD; break;
        case 1: blendType = LXColor.Blend.MULTIPLY; break;
        case 2: blendType = LXColor.Blend.LIGHTEST; break;
        case 3: blendType = LXColor.Blend.SUBTRACT; break;
        }
      }
    });
  }
  
  protected void computeBlend(int[] c1, int[] c2, double progress) {
    if (progress == 0) {
      for (int i = 0; i < colors.length; ++i) {
        colors[i] = c1[i];
      }
    } else if (progress == 1) {
      for (int i = 0; i < colors.length; ++i) {
        int color2 = (blendType == LXColor.Blend.SUBTRACT) ? LX.hsb(0, 0, LXColor.b(c2[i])) : c2[i]; 
        colors[i] = LXColor.blend(c1[i], color2, this.blendType);
      }
    } else {
      for (int i = 0; i < colors.length; ++i) {
        int color2 = (blendType == LXColor.Blend.SUBTRACT) ? LX.hsb(0, 0, LXColor.b(c2[i])) : c2[i];
        colors[i] = LXColor.lerp(c1[i], LXColor.blend(c1[i], color2, this.blendType), progress);
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


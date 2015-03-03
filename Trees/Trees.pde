static final boolean enableIPad = false;
static final boolean autoplayBMSet = true;

static final boolean enableNFC = false;
static final boolean enableAPC40 = false;
static final boolean enableSyphon = false;

static final boolean enableOutputMinitree = true;
static final boolean enableOutputBigtree = false;

static final String clusterMappingFile = "clusters.json";


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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static float CHAIN = -12*Geometry.INCHES;
final static float BOLT = 22*Geometry.INCHES;

final static String CLUSTER_CONFIG_FILE = "data/clusters.json";

LXPattern[] getPatternListForChannels() {
  ArrayList<LXPattern> patterns = new ArrayList<LXPattern>();
  // patterns.add(new OrderTest(lx));
  
  // Add patterns here.
  // The order here is the order it shows up in the patterns list
//  patterns.add(new SolidColor(lx));
  // patterns.add(new ClusterLineTest(lx));
  patterns.add(new Twister(lx));
  patterns.add(new CandyCloud(lx));
  patterns.add(new MarkLottor(lx));
  patterns.add(new SolidColor(lx));
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

  registerPattern(new Twister(lx), "3707000050a8fb");
  registerPattern(new MarkLottor(lx), "3707000050a8d5");
  registerPattern(new Ripple(lx), "3707000050a908");
  registerPattern(new Stripes(lx), "3707000050a8ad");
  registerPattern(new Lattice(lx), "3707000050a8b9");
  registerPattern(new Fumes(lx), "3707000050a9b1");
  registerPattern(new Voronoi(lx), "3707000050a952");
  registerPattern(new CandyCloud(lx), "3707000050aab4");
  registerPattern(new GalaxyCloud(lx), "3707000050a91d");

  registerPattern(new ColorStrobe(lx), "3707000050a975", 3);
  registerPattern(new Explosions(lx, 20), "3707000050a8bf", 3);
  registerPattern(new Strobe(lx), "3707000050ab3a", 3);
  registerPattern(new SparkleTakeOver(lx), "3707000050ab68", 3);
  registerPattern(new MultiSine(lx), "3707000050ab38", 3);
  registerPattern(new SeeSaw(lx), "3707000050ab76", 3);
  registerPattern(new Cells(lx), "3707000050abca", 3);
  registerPattern(new Fade(lx), "3707000050a8b0", 3);
  registerPattern(new Pixels(lx), "3707000050ab38", 3);
  
  registerPattern(new IceCrystals(lx), "3707000050a89b", 5);
  registerPattern(new Fire(lx), "-", 5); // Make red
  
  // registerPattern(new DoubleHelix(lx), "");
  registerPattern(new AcidTrip(lx), "3707000050a914");
  registerPattern(new Rain(lx), "3707000050a937");

  registerPattern(new Wisps(lx, 1, 60, 50, 270, 20, 3.5, 10), "3707000050a905"); // downward yellow wisp
  registerPattern(new Wisps(lx, 30, 210, 100, 90, 20, 3.5, 10), "3707000050ab1a"); // colorful wisp storm
  registerPattern(new Wisps(lx, 1, 210, 100, 90, 130, 3.5, 10), "3707000050aba4"); // multidirection colorful wisps
  registerPattern(new Wisps(lx, 3, 210, 10, 270, 0, 3.5, 10), ""); // rain storm of wisps
  registerPattern(new Wisps(lx, 35, 210, 180, 180, 15, 2, 15), "3707000050a8ee"); // twister of wisps
}

void registerOneShotTriggerables() {
  registerOneShot(new Pulleys(lx), "3707000050a939");
  registerOneShot(new StrobeOneshot(lx), "3707000050abb0");
  registerOneShot(new BassSlam(lx), "3707000050a991");
  registerOneShot(new Fireflies(lx, 70, 6, 180), "3707000050ab2e");
  registerOneShot(new Fireflies(lx, 40, 7.5, 90), "3707000050a92b");

  registerOneShot(new Fireflies(lx), "3707000050ab56", 5);
  registerOneShot(new Bubbles(lx), "3707000050a8ef", 5);
  registerOneShot(new Lightning(lx), "3707000050ab18", 5);
  registerOneShot(new Wisps(lx), "3707000050a9cd", 5);
  registerOneShot(new Explosions(lx), "3707000050ab6a", 5);
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

  registerEffectControlParameter(speedEffect.speed, "3707000050abae", 1, 0.4);
  registerEffectControlParameter(speedEffect.speed, "3707000050a916", 1, 5);
  registerEffectControlParameter(colorEffect.rainbow, "3707000050a98f");
  registerEffectControlParameter(colorEffect.mono, "3707000050aafe");
  registerEffectControlParameter(colorEffect.desaturation, "3707000050a969");
  registerEffectControlParameter(colorEffect.sharp, "3707000050aafc");
  registerEffectControlParameter(blurEffect.amount, "3707000050a973", 0.65);
  registerEffectControlParameter(spinEffect.spin, "3707000050ab2c", 0.65);
  registerEffectControlParameter(ghostEffect.amount, "3707000050aaf2", 0, 0.16, 1);
  registerEffectControlParameter(scrambleEffect.amount, "3707000050a8cc", 0, 1, 1);
  registerEffectControlParameter(colorStrobeTextureEffect.amount, "3707000050a946", 0, 1, 1);
  registerEffectControlParameter(fadeTextureEffect.amount, "3707000050a967", 0, 1, 1);
  registerEffectControlParameter(acidTripTextureEffect.amount, "3707000050a953", 0, 1, 1);
  registerEffectControlParameter(candyCloudTextureEffect.amount, "3707000050a92d", 0, 1, 1);
  registerEffectControlParameter(staticEffect.amount, "3707000050a8b3", 0, .3, 1);
  registerEffectControlParameter(candyTextureEffect.amount, "3707000050aafc", 0, 1, 5);

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
    VisualType.Pattern,
    VisualType.Pattern,
    VisualType.OneShot,
    VisualType.OneShot,
    VisualType.OneShot,
    VisualType.Effect,
    VisualType.Effect,
    VisualType.Effect,
    VisualType.Pattern,
  };
}

static List<TreeConfig> clusterConfig;
static Geometry geometry = new Geometry();

Model model;
P2LX lx;
LXDatagramOutput output;
LXDatagram[] datagrams;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
final BasicParameter drumpadVelocity = new BasicParameter("DVEL", 1);
BPMTool bpmTool;
MappingTool mappingTool;
LXAutomationRecorder[] automation = new LXAutomationRecorder[Engine.NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[Engine.NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", Engine.NUM_AUTOMATION);
LXListenableNormalizedParameter[] effectKnobParameters;
MidiEngine midiEngine;
TSDrumpad apc40Drumpad;
NFCEngine nfcEngine;
BooleanParameter[][] nfcToggles = new BooleanParameter[6][9];
BooleanParameter[] previewChannels = new BooleanParameter[Engine.NUM_CHANNELS];

void setup() {
  size(1148, 720, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  clusterConfig = loadJSONFile(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model(geometry, clusterConfig);
  
  lx = new P2LX(this, model);
  lx.engine.addParameter(drumpadVelocity);

  configureChannels();

  configureNFC();

  // uncomment this to allow any nfc reader to read any cube
  nfcEngine.disableVisualTypeRestrictions = true;

  configureTriggerables();

  lx.addEffect(mappingTool = new MappingTool(lx, clusterConfig));
  lx.engine.addLoopTask(new ModelTransformTask(model));
  lx.addEffect(new TurnOffDeadPixelsEffect(lx));

  configureBMPTool();

  configureAutomation();

  configureExternalOutput();
  configureFadeCandyOutput();

  configureUI();

  configureMIDI();
  
  // bad code I know
  // (shouldn't mess with engine internals)
  // maybe need a way to specify a deck shouldn't be focused?
  // essentially this lets us have extra decks for the drumpad
  // patterns without letting them be assigned to channels
  // -kf
  lx.engine.focusedChannel.setRange(Engine.NUM_CHANNELS);
  
  // Engine threading
  lx.engine.framesPerSecond.setValue(60);  
  lx.engine.setThreaded(true);
}

List<TreeConfig> loadJSONFile(String filename) {
  Reader reader = null;
  try {
    // for (int i = 0; i < args.length; i++) {
    //   if (args[i].startsWith(ARGS_SKETCH_FOLDER)){
    //     println(args[i].substring(args[i].indexOf('=') + 1));
    //   }
    // }
    reader = new BufferedReader(new FileReader(sketchPath(filename)));
    return new Gson().fromJson(reader, new TypeToken<List<TreeConfig>>() {}.getType());
  } catch (IOException ioe) { 
    System.out.println("Error reading json file: ");
    System.out.println(ioe);
  } finally {
    if (reader != null) {
      try {
        reader.close();
      } catch (IOException ioe) { }
    }
  }
  return null;
}

void saveJSONToFile(List<TreeConfig> config, String filename) {
  PrintWriter writer = null;
  try {
    writer = new PrintWriter(new BufferedWriter(new FileWriter(sketchPath(filename))));
    writer.write(new Gson().toJson(config));
  } catch (IOException ioe) {
    System.out.println("Error writing json file.");
  } finally {
    if (writer != null) {
      writer.close();
    }
  }
}

/* configureChannels */

void setupChannel(final LXChannel channel, boolean noOpWhenNotRunning) {
  channel.setFaderTransition(new TreesTransition(lx, channel));

  if (noOpWhenNotRunning) {
    channel.enabled.setValue(channel.getFader().getValue() != 0);
    channel.getFader().addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        channel.enabled.setValue(channel.getFader().getValue() != 0);
      }
    });
  }
}

void configureChannels() {
  lx.setPatterns(getPatternListForChannels());
  for (int i = 1; i < Engine.NUM_CHANNELS; ++i) {
    lx.engine.addChannel(getPatternListForChannels());
  }
  
  for (LXChannel channel : lx.engine.getChannels()) {
    channel.goIndex(channel.getIndex());
    setupChannel(channel, false);
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
  BooleanParameter toggle = apc40DrumpadTriggerablesLists[apc40DrumpadRow].size() < 9 ? nfcToggles[apc40DrumpadRow][apc40DrumpadTriggerablesLists[apc40DrumpadRow].size()] : null;
  nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, visualType, toggle);
  apc40DrumpadTriggerablesLists[apc40DrumpadRow].add(triggerable);
}

Triggerable configurePatternAsTriggerable(TSPattern pattern) {
  LXChannel channel = lx.engine.addChannel(new TSPattern[] { pattern });
  setupChannel(channel, true);

  pattern.onTriggerableModeEnabled();
  return pattern.getTriggerable();
}

/* configureEffects */

void registerEffect(LXEffect effect, String nfcSerialNumber) {
  if (effect instanceof Triggerable) {
    Triggerable triggerable = (Triggerable)effect;
    BooleanParameter toggle = apc40DrumpadTriggerablesLists[0].size() < 9 ? nfcToggles[0][apc40DrumpadTriggerablesLists[0].size()] : null;
    nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect, toggle);
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
  ParameterTriggerableAdapter triggerable = new ParameterTriggerableAdapter(lx, parameter, offValue, onValue);
    BooleanParameter toggle = apc40DrumpadTriggerablesLists[row].size() < 9 ? nfcToggles[row][apc40DrumpadTriggerablesLists[row].size()] : null;
  nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect, toggle);
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
  midiEngine = new MidiEngine(lx, effectKnobParameters, apc40Drumpad, drumpadVelocity, previewChannels, bpmTool, uiDeck, nfcToggles, output, automationSlot, automation, automationStop);
}

/* configureNFC */

void configureNFC() {
  nfcEngine = new NFCEngine(lx);
  nfcEngine.start();
  
  for (int i = 0; i < 6; i++) {
    for (int j = 0; j < 9; j++) {
      nfcToggles[i][j] = new BooleanParameter("toggle");
    }
  }

  nfcEngine.registerReaderPatternTypeRestrictions(Arrays.asList(readerPatternTypeRestrictions()));
}

/* configureUI */

void configureUI() {
  // UI initialization
  lx.ui.addLayer(new UI3dContext(lx.ui) {
      protected void beforeDraw(UI ui, PGraphics pg) {
        hint(ENABLE_DEPTH_TEST);
        pushMatrix();
        translate(0, 12*Geometry.FEET, 0);
      }
      protected void afterDraw(UI ui, PGraphics pg) {
        popMatrix();
        hint(DISABLE_DEPTH_TEST);
      }  
    }
    .setRadius(90*Geometry.FEET)
    .setCenter(model.cx, model.cy, model.cz)
    .setTheta(30*MathUtils.PI/180)
    .setPhi(10*MathUtils.PI/180)
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
      output.addDatagram(datagrams[ci++] = Output.clusterDatagram(cluster).setAddress(cluster.ipAddress));
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

class BooleanProxyParameter extends BooleanParameter {

  final List<BooleanParameter> parameters = new ArrayList<BooleanParameter>();

  BooleanProxyParameter() {
    super("Proxy", true);
  }

  protected double updateValue(double value) {
    for (BooleanParameter parameter : parameters) {
      parameter.setValue(value);
    }
    return value;
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


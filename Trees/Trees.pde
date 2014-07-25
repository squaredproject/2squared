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

void registerPatterns() {
  // Add patterns here.
  // The order here is the order it shows up in the patterns list

  // If you don't want to add it to NFC or the drumpad, don't specify the 2nd and 3rd parameters
  // The 2nd parameter is the NFC tag serial number
  // Specify a blank string to only add it to the apc40 drumpad
  // The 3rd parameter is which row of the apc40 drumpad to add it to. defaults to row 1
  registerPattern(new SolidColor(lx));
  registerPattern(new Twister(lx), "");
  registerPattern(new MarkLottor(lx), "");
  registerPattern(new DoubleHelix(lx), "");
  registerPattern(new SparkleHelix(lx));
  registerPattern(new Lightning(lx), "");
  registerPattern(new SparkleTakeOver(lx));
  registerPattern(new MultiSine(lx));
  registerPattern(new Ripple(lx), "");
  registerPattern(new SeeSaw(lx));
  registerPattern(new SweepPattern(lx));
  registerPattern(new IceCrystals(lx), "", 2);
  registerPattern(new ColoredLeaves(lx));
  registerPattern(new Stripes(lx), "", 2);
  try { registerPattern(new SyphonPattern(lx, this)); } catch (Throwable e) {}
  registerPattern(new AcidTrip(lx), "", 2);
  registerPattern(new Springs(lx));
  registerPattern(new Lattice(lx), "", 2);
  registerPattern(new Fire(lx), "", 3);
  registerPattern(new Fireflies(lx), "", 3);
  registerPattern(new Fumes(lx), "", 3);
  registerPattern(new Voronoi(lx), "", 3);
  registerPattern(new Bubbles(lx), "", 3);
  registerPattern(new Pulleys(lx), "", 3);

  registerPattern(new Wisps(lx), "", 4);
  registerPattern(new Explosions(lx), "044d575a312c80", 4);
  registerPattern(new BassSlam(lx));
  registerPattern(new Rain(lx));
  registerPattern(new Fade(lx));
  registerPattern(new Strobe(lx));
  registerPattern(new Twinkle(lx));
  registerPattern(new VerticalSweep(lx));
  registerPattern(new RandomColor(lx));
  registerPattern(new RandomColorAll(lx), "04ad5f62312c80", 4);
  registerPattern(new Pixels(lx));
  registerPattern(new Wedges(lx));
  registerPattern(new Parallax(lx));
  registerPattern(new LowEQ(lx));
  registerPattern(new MidEQ(lx));
  registerPattern(new HighEQ(lx));
}

void registerEffects() {
  BlurEffect blurEffect;
  ColorEffect colorEffect;
  GhostEffect ghostEffect;
  ScrambleEffect scrambleEffect;

  registerEffect(blurEffect = new BlurEffect(lx));
  registerEffect(colorEffect = new ColorEffect(lx));
  registerEffect(ghostEffect = new GhostEffect(lx));
  registerEffect(scrambleEffect = new ScrambleEffect(lx));
  registerEffect(new SpeedEffect(lx, 0.4), "");
  registerEffect(new SpeedEffect(lx, 5), "");

  registerEffectControlParameter(colorEffect.hueShift);
  registerEffectControlParameter(colorEffect.rainbow, "");
  registerEffectControlParameter(colorEffect.mono, "");
  registerEffectControlParameter(colorEffect.desaturation, "04346762312c80");
  registerEffectControlParameter(colorEffect.sharp, "");
  registerEffectControlParameter(blurEffect.amount, "", 0.65);
  registerEffectControlParameter(ghostEffect.amount, "", 0.16);
  registerEffectControlParameter(scrambleEffect.amount, "");
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
LX lx;
LXDatagramOutput output;
LXDatagram[] datagrams;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
final BasicParameter bgLevel = new BasicParameter("BG", 25, 0, 50);
final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
BPMTool bpmTool;
MappingTool mappingTool;
LXAutomationRecorder[] automation = new LXAutomationRecorder[NUM_AUTOMATION];
BooleanParameter[] automationStop = new BooleanParameter[NUM_AUTOMATION]; 
DiscreteParameter automationSlot = new DiscreteParameter("AUTO", NUM_AUTOMATION);
LXListenableNormalizedParameter[] effectKnobParameters;
MidiEngine midiEngine;
TSDrumpad mpk25Drumpad;
TSDrumpad apc40Drumpad;
TSKeyboard keyboard;
Minim minim;
NFCEngine nfcEngine;

void setup() {
  size(1024, 680, OPENGL);
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  clusterConfig = loadJSONArray(CLUSTER_CONFIG_FILE);
  geometry = new Geometry();
  model = new Model();
  
  minim = new Minim(this);
  
  lx = new LX(this, model);

  configureChannels();

  configureKeyboard();

  configureNFC();

  configureTriggerables();

  configureEffects();

  registerEffect(mappingTool = new MappingTool(lx));

  configureBMPTool();

  configureAutomation();

  configureExternalOutput();

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

ArrayList<LXPattern> patterns;
boolean configurePatternsAsTriggerables;

void configureChannels() {
  configurePatternsAsTriggerables = false;

  patterns = new ArrayList<LXPattern>();
  registerPatterns();
  lx.setPatterns(patterns.toArray(new LXPattern[patterns.size()]));
  for (int i = 1; i < NUM_CHANNELS - (isMPK25Connected() ? 1 : 0); ++i) {
    patterns = new ArrayList<LXPattern>();
    registerPatterns();
    lx.engine.addChannel(patterns.toArray(new LXPattern[patterns.size()]));
  }
  
  for (LXChannel channel : lx.engine.getChannels()) {
    channel.goIndex(channel.getIndex());
    channel.setFaderTransition(new TreesTransition(lx, channel));
  }
  patterns = null;
}

void registerPattern(LXPattern pattern) {
  registerPattern(pattern, null);
}

void registerPattern(LXPattern pattern, String nfcSerialNumber) {
  registerPattern(pattern, nfcSerialNumber, 1);
}

void registerPattern(LXPattern pattern, String nfcSerialNumber, int apc40DrumpadRow) {
  if (configurePatternsAsTriggerables && nfcSerialNumber == null) {
    return;
  }

  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  pattern.setTransition(t);

  if (configurePatternsAsTriggerables) {
    Triggerable triggerable = configurePatternAsTriggerable(pattern);
    nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Pattern);
    apc40DrumpadTriggerablesLists[apc40DrumpadRow].add(triggerable);
  } else {
    patterns.add(pattern);
  }
}

Triggerable configurePatternAsTriggerable(LXPattern pattern) {
  LXChannel channel = lx.engine.addChannel(new LXPattern[] { pattern });
  channel.setFaderTransition(new TreesTransition(lx, channel));

  Triggerable triggerable;
  if (pattern instanceof Triggerable) {
    triggerable = (Triggerable)pattern;
    triggerable.enableTriggerableMode();
    channel.getFader().setValue(1);
  } else {
    triggerable = new ParameterTriggerableAdapter(channel.getFader());
  }
  return triggerable;
}

/* configureEffects */

ArrayList<LXListenableNormalizedParameter> effectKnobParametersList;
boolean configureEffectsAsTriggerables;

void configureEffects() {
  configureEffectsAsTriggerables = false;
  effectKnobParametersList = new ArrayList<LXListenableNormalizedParameter>();
  registerEffects();
  effectKnobParameters = effectKnobParametersList.toArray(new LXListenableNormalizedParameter[effectKnobParametersList.size()]);
  effectKnobParametersList = null;
}

void registerEffect(LXEffect effect) {
  registerEffect(effect, null);
}
void registerEffect(LXEffect effect, String nfcSerialNumber) {
  if (configurePatternsAsTriggerables && nfcSerialNumber == null) {
    return;
  }

  lx.addEffect(effect);

  if (configureEffectsAsTriggerables) {
    if (effect instanceof Triggerable) {
      Triggerable triggerable = (Triggerable)effect;
      triggerable.enableTriggerableMode();
      nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect);
      apc40DrumpadTriggerablesLists[0].add(triggerable);
    }
  }
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter) {
  registerEffectControlParameter(parameter, null);
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber) {
  registerEffectControlParameter(parameter, nfcSerialNumber, 0, 1);
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber, double onValue) {
  registerEffectControlParameter(parameter, nfcSerialNumber, 0, onValue);
}

void registerEffectControlParameter(LXListenableNormalizedParameter parameter, String nfcSerialNumber, double offValue, double onValue) {
  if (configureEffectsAsTriggerables) {
    Triggerable triggerable = new ParameterTriggerableAdapter(parameter, offValue, onValue);
    if (nfcSerialNumber != null) {
      nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect);
      apc40DrumpadTriggerablesLists[0].add(triggerable);
    }
  } else {
    effectKnobParametersList.add(parameter);
  }
}

/* configureKeyboard */

void configureKeyboard() {
  if (isMPK25Connected()) {
    keyboard = new TSKeyboard();
    keyboard.configure(lx);
  }
}

/* configureBMPTool */

void configureBMPTool() {
  bpmTool = new BPMTool(lx, effectKnobParameters);
}

/* configureAutomation */

void configureAutomation() {
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
    new ArrayList<Triggerable>()
  };

  configurePatternsAsTriggerables = true;
  registerPatterns();

  configureEffectsAsTriggerables = true;
  registerEffects();

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
  if (midiEngine.mpk25 != null) {
    // Drumpad
    mpk25Drumpad = new TSDrumpad();
    midiEngine.mpk25.setDrumpad(mpk25Drumpad);

    midiEngine.mpk25.setKeyboard(keyboard);
  }
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


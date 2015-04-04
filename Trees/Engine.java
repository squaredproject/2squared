import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.Reader;
import java.lang.reflect.Type;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;

import com.google.gson.Gson;
import com.google.gson.JsonArray;
import com.google.gson.reflect.TypeToken;

import heronarts.lx.LX;
import heronarts.lx.LXAutomationRecorder;
import heronarts.lx.LXChannel;
import heronarts.lx.LXEngine;
import heronarts.lx.color.LXColor;
import heronarts.lx.effect.BlurEffect;
import heronarts.lx.effect.LXEffect;
import heronarts.lx.model.LXModel;
import heronarts.lx.output.FadecandyOutput;
import heronarts.lx.output.LXDatagram;
import heronarts.lx.output.LXDatagramOutput;
import heronarts.lx.parameter.BasicParameter;
import heronarts.lx.parameter.BooleanParameter;
import heronarts.lx.parameter.DiscreteParameter;
import heronarts.lx.parameter.LXListenableNormalizedParameter;
import heronarts.lx.parameter.LXParameter;
import heronarts.lx.parameter.LXParameterListener;
import heronarts.lx.pattern.LXPattern;
import heronarts.lx.transition.DissolveTransition;
import heronarts.lx.transition.LXTransition;

abstract class Engine {
  static final boolean enableIPad = false;
  static final boolean autoplayBMSet = true;

  static final boolean enableNFC = false;
  static final boolean enableAPC40 = false;

  static final boolean enableOutputMinitree = true;
  static final boolean enableOutputBigtree = false;

  static final String CLUSTER_CONFIG_FILE = "data/clusters.json";


  static final int NUM_CHANNELS = 8;
  static final int NUM_KNOBS = 8;
  static final int NUM_AUTOMATION = 4;

  final String projectPath;
  final List<TreeConfig> clusterConfig;
  final LX lx;
  final Model model;
  LXDatagramOutput output;
  LXDatagram[] datagrams;
  BPMTool bpmTool;
  MappingTool mappingTool;
  InterfaceController uiDeck;
  MidiEngine midiEngine;
  TSDrumpad apc40Drumpad;
  NFCEngine nfcEngine;
  LXListenableNormalizedParameter[] effectKnobParameters;
  final BasicParameter dissolveTime = new BasicParameter("DSLV", 400, 50, 1000);
  final BasicParameter drumpadVelocity = new BasicParameter("DVEL", 1);
  final LXAutomationRecorder[] automation = new LXAutomationRecorder[Engine.NUM_AUTOMATION];
  final BooleanParameter[] automationStop = new BooleanParameter[Engine.NUM_AUTOMATION]; 
  final DiscreteParameter automationSlot = new DiscreteParameter("AUTO", Engine.NUM_AUTOMATION);
  final BooleanParameter[][] nfcToggles = new BooleanParameter[6][9];
  final BooleanParameter[] previewChannels = new BooleanParameter[Engine.NUM_CHANNELS];
  final BasicParameterProxy outputBrightness = new BasicParameterProxy(1);

  Engine(String projectPath) {
    this.projectPath = projectPath;

    clusterConfig = loadConfigFile(CLUSTER_CONFIG_FILE);
    model = new Model(clusterConfig);
    lx = createLX();
  
    lx.engine.addParameter(drumpadVelocity);

    configureChannels();

    if (enableNFC) {
      configureNFC();

      // uncomment this to allow any nfc reader to read any cube
      nfcEngine.disableVisualTypeRestrictions = true;
    }

    configureTriggerables();

    lx.addEffect(mappingTool = new MappingTool(lx, clusterConfig));
    lx.engine.addLoopTask(new ModelTransformTask(model));

    configureBMPTool();

    configureAutomation();

    if (enableOutputBigtree) {
      lx.addEffect(new TurnOffDeadPixelsEffect(lx));
      configureExternalOutput();
    }
    if (enableOutputMinitree) {
      configureFadeCandyOutput();
    }

    postCreateLX();

    if (enableAPC40) {
      configureMIDI();
    }
    
    // bad code I know
    // (shouldn't mess with engine internals)
    // maybe need a way to specify a deck shouldn't be focused?
    // essentially this lets us have extra decks for the drumpad
    // patterns without letting them be assigned to channels
    // -kf
    lx.engine.focusedChannel.setRange(Engine.NUM_CHANNELS);
  }

  void start() {
    lx.engine.start();
  }

  abstract LX createLX();

  void postCreateLX() { }

  void addPatterns(ArrayList<LXPattern> patterns) {
    // Add patterns here.
    // The order here is the order it shows up in the patterns list
  //  patterns.add(new SolidColor(lx));
    // patterns.add(new ClusterLineTest(lx));
    // patterns.add(new OrderTest(lx));
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
  }

  LXPattern[] getPatternListForChannels() {
    ArrayList<LXPattern> patterns = new ArrayList<LXPattern>();
    
    addPatterns(patterns);

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
    registerOneShot(new Fireflies(lx, 40, 7.5f, 90), "3707000050a92b");

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

  String sketchPath(String filename) {
    return projectPath + "/" + filename;
  }

  List<TreeConfig> loadConfigFile(String filename) {
    return loadJSONFile(filename, new TypeToken<List<TreeConfig>>() {}.getType());
  }

  JsonArray loadSavedSetFile(String filename) {
    return loadJSONFile(filename, JsonArray.class);
  }

  <T> T loadJSONFile(String filename, Type typeToken) {
    Reader reader = null;
    try {
      reader = new BufferedReader(new FileReader(sketchPath(filename)));
      return new Gson().fromJson(reader, typeToken);
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
      setupChannel(channel, true);
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
    BooleanParameter toggle = null;
    if (apc40Drumpad != null) {
      toggle = apc40DrumpadTriggerablesLists[apc40DrumpadRow].size() < 9 ? nfcToggles[apc40DrumpadRow][apc40DrumpadTriggerablesLists[apc40DrumpadRow].size()] : null;
      apc40DrumpadTriggerablesLists[apc40DrumpadRow].add(triggerable);
    }
    if (nfcEngine != null) {
      nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, visualType, toggle);
    }
  }

  Triggerable configurePatternAsTriggerable(TSPattern pattern) {
    LXChannel channel = lx.engine.addChannel(new TSPattern[] { pattern });
    setupChannel(channel, false);

    pattern.onTriggerableModeEnabled();
    return pattern.getTriggerable();
  }

  /* configureEffects */

  void registerEffect(LXEffect effect, String nfcSerialNumber) {
    if (effect instanceof Triggerable) {
      Triggerable triggerable = (Triggerable)effect;
      BooleanParameter toggle = null;
      if (apc40Drumpad != null) {
        toggle = apc40DrumpadTriggerablesLists[0].size() < 9 ? nfcToggles[0][apc40DrumpadTriggerablesLists[0].size()] : null;
        apc40DrumpadTriggerablesLists[0].add(triggerable);
      }
      if (nfcEngine != null) {
        nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect, toggle);
      }
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
      BooleanParameter toggle = null;
    if (apc40Drumpad != null) {
      toggle = apc40DrumpadTriggerablesLists[row].size() < 9 ? nfcToggles[row][apc40DrumpadTriggerablesLists[row].size()] : null;
      apc40DrumpadTriggerablesLists[row].add(triggerable);
    }
    if (nfcEngine != null) {
      nfcEngine.registerTriggerable(nfcSerialNumber, triggerable, VisualType.Effect, toggle);
    }
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
          outputBrightness.setValue(value);
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

    if (autoplayBMSet) {
      String filename = "data/Burning Man Playlist.json";
      JsonArray jsonArr = loadSavedSetFile(filename);
      automation[automationSlot.getValuei()].loadJson(jsonArr);
      // slotLabel.setLabel(labels[automationSlot.getValuei()] = filename);

      automation[automationSlot.getValuei()].looping.setValue(true);
      automation[automationSlot.getValuei()].start();
    }
  }

  /* configureTriggerables */
  
  ArrayList<Triggerable>[] apc40DrumpadTriggerablesLists;
  Triggerable[][] apc40DrumpadTriggerables;

  @SuppressWarnings("unchecked")
  void configureTriggerables() {
    if (apc40Drumpad != null) {
      apc40DrumpadTriggerablesLists = new ArrayList[] {
        new ArrayList<Triggerable>(),
        new ArrayList<Triggerable>(),
        new ArrayList<Triggerable>(),
        new ArrayList<Triggerable>(),
        new ArrayList<Triggerable>(),
        new ArrayList<Triggerable>()
      };
    }

    registerPatternTriggerables();
    registerOneShotTriggerables();
    registerEffectTriggerables();

    if (apc40Drumpad != null) {
      apc40DrumpadTriggerables = new Triggerable[apc40DrumpadTriggerablesLists.length][];
      for (int i = 0; i < apc40DrumpadTriggerablesLists.length; i++) {
        ArrayList<Triggerable> triggerablesList= apc40DrumpadTriggerablesLists[i];
        apc40DrumpadTriggerables[i] = triggerablesList.toArray(new Triggerable[triggerablesList.size()]);
      }
      apc40DrumpadTriggerablesLists = null;
    }
  }

  /* configureMIDI */

  void configureMIDI() {
    apc40Drumpad = new TSDrumpad();
    apc40Drumpad.triggerables = apc40DrumpadTriggerables;

    // MIDI control
    midiEngine = new MidiEngine(lx, effectKnobParameters, apc40Drumpad, drumpadVelocity, previewChannels, bpmTool, uiDeck, nfcToggles, outputBrightness, automationSlot, automation, automationStop);
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
      outputBrightness.parameters.add(output.brightness);
      output.enabled.setValue(false);
      lx.addOutput(output);
    } catch (Exception x) {
      System.out.println(x);
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
      outputBrightness.parameters.add(fadecandyOutput.brightness);
      lx.addOutput(fadecandyOutput);
    } catch (Exception e) {
      System.out.println(e);
    }
  }
}

class TreesTransition extends LXTransition {
  
  private final LXChannel channel;
  
  public final DiscreteParameter blendMode = new DiscreteParameter("MODE", 4);
  private LXColor.Blend blendType = LXColor.Blend.ADD;

  final BasicParameter fade = new BasicParameter("FADE", 1);
    
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

class BooleanParameterProxy extends BooleanParameter {

  final List<BooleanParameter> parameters = new ArrayList<BooleanParameter>();

  BooleanParameterProxy() {
    super("Proxy", true);
  }

  protected double updateValue(double value) {
    for (BooleanParameter parameter : parameters) {
      parameter.setValue(value);
    }
    return value;
  }
}

class BasicParameterProxy extends BasicParameter {

  final List<BasicParameter> parameters = new ArrayList<BasicParameter>();

  BasicParameterProxy(double value) {
    super("Proxy", value);
  }

  protected double updateValue(double value) {
    for (BasicParameter parameter : parameters) {
      parameter.setValue(value);
    }
    return value;
  }
}

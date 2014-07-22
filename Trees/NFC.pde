NFCEngine nfcEngine = null;

void configureNFC() {
  nfcEngine = new NFCEngine(lx);
  nfcEngine.start();
  
  populateNFCEngine();

  configureReaders();
  
  println("NFC configured");
}

void populateNFCEngine() {
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.rainbow), VisualType.Effect);
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.mono), VisualType.Effect);
  nfcEngine.registerTriggerable("04346762312c80", new ParameterTriggerableAdapter(colorEffect.desaturation), VisualType.Effect);
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.sharp), VisualType.Effect);
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(blurEffect.amount), VisualType.Effect);
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(ghostEffect.amount), VisualType.Effect);
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(scrambleEffect.amount), VisualType.Effect);

  configurePattern("", new Brightness(lx), VisualType.Pattern);
  configurePattern("044d575a312c80", new Explosions(lx), VisualType.Pattern);
  configurePattern("", new Wisps(lx), VisualType.Pattern);
  // configurePattern("", new Lightning(lx), VisualType.Pattern); // a little slow
  // configurePattern("", new Pulley(lx), VisualType.Pattern); // broken?

  configurePattern("", new Twister(lx), VisualType.Pattern);
  // configurePattern("", new MarkLottor(lx), VisualType.Pattern); // a little slow
  configurePattern("", new DoubleHelix(lx), VisualType.Pattern);
  configurePattern("", new Ripple(lx), VisualType.Pattern);
  // configurePattern("", new IceCrystals(lx), VisualType.Pattern); // slow
  configurePattern("", new Stripes(lx), VisualType.Pattern);
  configurePattern("", new AcidTrip(lx), VisualType.Pattern);
  configurePattern("", new Lattice(lx), VisualType.Pattern);
  configurePattern("", new Fire(lx), VisualType.Pattern);
  configurePattern("", new FirefliesExp(lx), VisualType.Pattern);
  // configurePattern("", new Fumes(lx)); // a little slow
  // configurePattern("", new Voronoi(lx)); // a little slow
  configurePattern("", new Bubbles(lx), VisualType.Pattern);
  configurePattern("04ad5f62312c80", new RandomColorAll(lx), VisualType.Pattern);
}

void configurePattern(String serialNumber, LXPattern pattern, VisualType VisualType) {
  LXTransition t = new DissolveTransition(lx).setDuration(dissolveTime);
  pattern.setTransition(t);
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
  nfcEngine.registerTriggerable(serialNumber, triggerable, VisualType);
}

void configureReaders() {
  nfcEngine.registerReaderPatternTypeRestrictions(Arrays.asList(new VisualType[] {
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
  }));
}

public class NFCEngine {
  private class NFCEngineCardListener implements NFCCardListener {
    public void onReaderAdded(String reader) {
      VisualType nextPatternType = readerPatternTypeRestrictionArray.get(readerPatternTypeRestrictionIndex);
      readerPatternTypeRestrictionIndex++;
      readerToPatternTypeRestrictionMap.put(reader, nextPatternType);
    }

    public void onReaderRemoved(String reader) {
      readerPatternTypeRestrictionIndex = 0;
      readerToPatternTypeRestrictionMap.clear();
    }

    public void onCardAdded(String reader, String cardId) {
      NFCEngineVisual visual = cardToTriggerableMap.get(cardId);
      if (visual != null) {
        VisualType readerRestriction = readerToPatternTypeRestrictionMap.get(reader);
        if (readerRestriction == visual.VisualType) {
          visual.triggerable.onTriggered(1);
        }
      }
      println(reader, "added card", cardId);
    }
    
    public void onCardRemoved(String reader, String cardId) {
      NFCEngineVisual visual = cardToTriggerableMap.get(cardId);
      if (visual != null) {
        VisualType readerRestriction = readerToPatternTypeRestrictionMap.get(reader);
        if (readerRestriction == visual.VisualType) {
          visual.triggerable.onRelease();
        }
      }
    }
  }

  private class NFCEngineVisual {
    Triggerable triggerable;
    VisualType VisualType;

    NFCEngineVisual(Triggerable triggerable, VisualType VisualType) {
      this.triggerable = triggerable;
      this.VisualType = VisualType;
    }
  }

  private final LX lx;
  private LibNFC libNFC;
  private LibNFCMainThread libNFCMainThread;
  private final NFCEngineCardListener cardReader = new NFCEngineCardListener();
  private final Map<String, NFCEngineVisual> cardToTriggerableMap = new HashMap<String, NFCEngineVisual>();
  private final Map<String, VisualType> readerToPatternTypeRestrictionMap = new HashMap<String, VisualType>();
  private List<VisualType> readerPatternTypeRestrictionArray;
  private int readerPatternTypeRestrictionIndex = 0;
  
  public NFCEngine(LX lx) {
    this.lx = lx;
    try {
      libNFC = new LibNFC();
      libNFCMainThread = new LibNFCMainThread(libNFC, cardReader);
    } catch(Exception e) {
      println("nfc engine initialization error: " + e.toString());
      libNFC = null;
      libNFCMainThread = null;
    }
  }
  
  public void start() {
    if (libNFCMainThread != null) {
      libNFCMainThread.start();
    }
  }
  
  public void stop() {
    if (libNFCMainThread != null) {
      libNFCMainThread.stop();
    }
  }
  
  public void registerTriggerable(String serialNumber, Triggerable triggerable, VisualType VisualType) {
    cardToTriggerableMap.put(serialNumber, new NFCEngineVisual(triggerable, VisualType));
  }

  public void registerReaderPatternTypeRestrictions(List<VisualType> readerPatternTypeRestrictionArray) {
    this.readerPatternTypeRestrictionArray = readerPatternTypeRestrictionArray;
  }
}

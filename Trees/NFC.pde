NFCEngine nfcEngine = null;

void configureNFC() {
  nfcEngine = new NFCEngine(lx);
  nfcEngine.start();
  
  populateNFCEngine();
  
  println("NFC configured");
}

void populateNFCEngine() {
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.rainbow));
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.mono));
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.desaturation));
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(colorEffect.sharp));
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(blurEffect.amount));
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(ghostEffect.amount));
  nfcEngine.registerTriggerable("", new ParameterTriggerableAdapter(scrambleEffect.amount));

  configurePattern("", new Brightness(lx));
  configurePattern("", new Explosions(lx));
  configurePattern("", new Wisps(lx));
  // configurePattern("", new Lightning(lx)); // a little slow
  // configurePattern("", new Pulley(lx)); // broken?

  configurePattern("", new Twister(lx));
  // configurePattern("", new MarkLottor(lx)); // a little slow
  configurePattern("", new DoubleHelix(lx));
  configurePattern("", new Ripple(lx));
  // configurePattern("", new IceCrystals(lx)); // slow
  configurePattern("", new Stripes(lx));
  configurePattern("", new AcidTrip(lx));
  configurePattern("", new Lattice(lx));
  configurePattern("", new Fire(lx));
  configurePattern("", new FirefliesExp(lx));
  // configurePattern("", new Fumes(lx)); // a little slow
  // configurePattern("", new Voronoi(lx)); // a little slow
  configurePattern("", new Bubbles(lx));
  configurePattern("04ad5f62312c80", new RandomColorAll(lx));
}

void configurePattern(String serialNumber, LXPattern pattern) {
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
  nfcEngine.registerTriggerable(serialNumber, triggerable);
}

public class NFCEngine {
  private class NFCEngineCardListener implements NFCCardListener {
    public void onCardAdded(String reader, String cardId) {
      Triggerable triggerable = cardToTriggerableMap.get(cardId);
      if (triggerable != null) {
        triggerable.onTriggered(1);
      }
    }
    
    public void onCardRemoved(String reader, String cardId) {
      Triggerable triggerable = cardToTriggerableMap.get(cardId);
      if (triggerable != null) {
        triggerable.onRelease();
      }
    }
  }

  private final LX lx;
  private LibNFC libNFC;
  private LibNFCMainThread libNFCMainThread;
  private final NFCEngineCardListener cardReader = new NFCEngineCardListener();
  private final Map<String, Triggerable> cardToTriggerableMap = new HashMap<String, Triggerable>();
  
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
  
  public void registerTriggerable(String serialNumber, Triggerable triggerable) {
    cardToTriggerableMap.put(serialNumber, triggerable);
  }
}

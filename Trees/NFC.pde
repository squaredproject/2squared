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

import java.util.logging.Logger;
import java.util.logging.Level;

// "34f662a3", "360558b3", "14a563a3", "1490aec6", "446bebc4", "04836632"

final static RequestAPDU serialNumberRequestAPDU = new RequestAPDU(0xFF, 0xCA, 0x00, 0x00, 4);
final static RequestAPDU noBeepRequestAPDU = new RequestAPDU(0xFF, 0x00, 0x52, 0x00, 6);

void configureNFC() {
  turnOffSmartcardLibraryLogging();
  
  if (!isPCSCDaemonRunning()) {
    Logger.getGlobal().warning("NFC not configured: couldn't establish connection to PC/SC daemon");
    return;
  }
  
  ICardSystem cardSystem = new StandardCardSystem(PCSCContextFactory.get());
  CardSystemMonitor cardSystemMonitor = new CardSystemMonitor(cardSystem);
  cardSystemMonitor.addCardSystemListener(new NFCCardSystemMonitor());
  cardSystemMonitor.start();
  
  println("NFC configured");
}

void turnOffSmartcardLibraryLogging() {
  Logger[] loggers = {
    Logger.getLogger("de.intarsys.security.smartcard.pcsc"),
    Logger.getLogger("de.intarsys.security.smartcard.card")
  };
  for (Logger l : loggers) {
    l.setLevel(Level.OFF);
  }
}

boolean isPCSCDaemonRunning() {
  try {
    PCSCContextFactory.get().establishContext().dispose();
  } catch (Exception e) {
    return false;
  }
  return true;
}

class NFCCardSystemMonitor implements CardSystemMonitor.ICardSystemListener {
  private boolean willBeep = true;
  
  private void turnOffBeep(ICardConnection connection) {
    try {
      connection.transmit(noBeepRequestAPDU);
      willBeep = false;
    } catch (Exception e) {
      Logger.getGlobal().warning("" + e);
    }
  }
  
  private String getSerialNumber(ICardConnection connection) {
    ResponseAPDU response;
    try {
      response = connection.transmit(serialNumberRequestAPDU);
    } catch (Exception e) {
      Logger.getGlobal().warning("" + e);
      return null;
    }
    byte[] serialNumberBytes = response.getData();
    StringBuilder sb = new StringBuilder(serialNumberBytes.length * 2);
    for (byte b : serialNumberBytes) {
      sb.append(String.format("%02x", b));
    }
    return sb.toString();
  }
  
  private void closeConnection(ICardConnection connection) {
    try {
      connection.close(ICardConnection.MODE_RESET);
    } catch (Exception e) {
      Logger.getGlobal().warning("" + e);
    }
  }
  
  public void onCardInserted(ICard card) {
    // TODO: cache serial numbers. possible?
    card.connectShared(_IPCSC.SCARD_PROTOCOL_T1, new IConnectionCallback() {
      public void connected(ICardConnection connection) {
        try {
          if (willBeep) {
            turnOffBeep(connection);
          }
          String serialNumber = getSerialNumber(connection);
          if (serialNumber != null) {
            println(serialNumber);
            // TODO: Trigger cube placed
          }
        } finally {
          closeConnection(connection);
        }
      }
      
      public void connectionFailed(CardException exception) {}
    });
  }
  
  public void onCardRemoved(ICard card) {
    // TODO: Trigger cube removed
  }
  
  public void onCardChanged(ICard card) {}
  public void onCardTerminalConnected(ICardTerminal terminal) {}
  public void onCardTerminalDisconnected(ICardTerminal terminal) {}
}


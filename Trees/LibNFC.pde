static final int NFC_BUFSIZE_CONNSTRING = 1024;
static final int DEVICE_NAME_LENGTH = 256;
static final int DEVICE_PORT_LENGTH = 64;
static final int MAX_USER_DEFINED_DEVICES = 4;

static final long DEFAULT_MODULATION = 0x100000001l;

interface LibNFC extends Library {
    LibNFC INSTANCE = (LibNFC)Native.loadLibrary("nfc", LibNFC.class);

    void nfc_init(PointerByReference context);
    Pointer nfc_open(Pointer context, Pointer connstring);
    int nfc_initiator_init(Pointer p);

    int nfc_initiator_select_passive_target(Pointer pnd, long nm, Pointer pbtInitData, long szInitData, nfc_target nt);
    int nfc_initiator_list_passive_targets(Pointer pnd, long nm, nfc_target ant[], long szTargets);
    String nfc_device_get_name(Pointer p);

    void nfc_close(Pointer pnd);
    void nfc_exit(Pointer context);
}

public class nfc_target extends Structure {
    public byte head[];
    public byte size;
    public byte padding[];
    public byte serial[];
    public byte tail[];
    public nfc_target(){
        head = new byte[3];
        padding = new byte[7];
        serial = new byte[10];
        tail = new byte[280];
    }
    protected List getFieldOrder() {
      return Arrays.asList(new String[] {"head", "size", "padding", "serial", "tail"});
    }
}

void libNFCTest() {
    Pointer pnd;
    PointerByReference context = new PointerByReference();

    LibNFC.INSTANCE.nfc_init(context);
    println("context", context.getValue());
    if (context.getValue() == Pointer.NULL){
      println("nfc_init failed");
      return;
    }
    pnd = LibNFC.INSTANCE.nfc_open(context.getValue(), Pointer.NULL);
    println("pnd", pnd);
    if (LibNFC.INSTANCE.nfc_initiator_init(pnd) < 0) {
      println("failed initiator init");
      return;
    }
    println("NFC reader:", LibNFC.INSTANCE.nfc_device_get_name(pnd));

    nfc_target nt = new nfc_target();

    if (LibNFC.INSTANCE.nfc_initiator_select_passive_target(pnd, DEFAULT_MODULATION, Pointer.NULL, 0, nt) > 0){
      println("Found card.");
      System.out.printf("len: %d\n", nt.size);
      for(int j=0; j<nt.size; ++j){
          System.out.printf("%02x ", nt.serial[j]);
      }
      System.out.println();
    } else {
      println("No card.");
    }

    LibNFC.INSTANCE.nfc_close(pnd);
    LibNFC.INSTANCE.nfc_exit(context.getValue());
    exit();
}

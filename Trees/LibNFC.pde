static final int NFC_BUFSIZE_CONNSTRING = 1024;
static final int DEVICE_NAME_LENGTH = 256;
static final int DEVICE_PORT_LENGTH = 64;
static final int MAX_USER_DEFINED_DEVICES = 4;

static final long DEFAULT_MODULATION = 0x100000001l;

interface NFCLib extends Library {
    NFCLib INSTANCE = (NFCLib)Native.loadLibrary("nfc", NFCLib.class);

    void nfc_init(PointerByReference context);
    Pointer nfc_open(Pointer context, Pointer connstring);
    Pointer nfc_open(Pointer context, String connstring);
    int nfc_initiator_init(Pointer p);

    int nfc_list_devices(Pointer context, Pointer connstring, int connstring_len);

    int nfc_initiator_select_passive_target(Pointer pnd, long nm, Pointer pbtInitData, int szInitData, LibNFC.nfc_target nt);
    int nfc_initiator_list_passive_targets(Pointer pnd, long nm, LibNFC.nfc_target ant[], long szTargets);
    String nfc_device_get_name(Pointer p);

    void nfc_close(Pointer pnd);
    void nfc_exit(Pointer context);
}

public class LibNFC {
    private PointerByReference context;
    private List nd_list;
    private int num_readers;
    private int max_num_readers;

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

    public class card_id {
        byte id[];
        public card_id(nfc_target nt) {
            id = new byte[nt.size];
            System.arraycopy(nt.serial, 0, id, 0, nt.size);
        }
        public String toString(){
            String s = "";
            for(byte b : id){
                s += String.format("%02x ", b);
            }
            return s;
        }
    }

    public LibNFC() throws Exception{
        num_readers = 0;
        max_num_readers = 5;
        context = new PointerByReference();
        NFCLib.INSTANCE.nfc_init(context);
        if (context.getValue() == Pointer.NULL){
            throw new Exception("nfc_init failed.");
        }
        nd_list = new ArrayList();

        Memory connstrings = new Memory(max_num_readers * NFC_BUFSIZE_CONNSTRING);

        num_readers = NFCLib.INSTANCE.nfc_list_devices(context.getValue(), connstrings.share(0), max_num_readers);

        Pointer pnd;
        for(int i=0 ; i < num_readers; ++i){
            //println("Trying reader:", connstrings.getString(i*NFC_BUFSIZE_CONNSTRING, false));

            pnd = NFCLib.INSTANCE.nfc_open(context.getValue(), connstrings.getString(i*NFC_BUFSIZE_CONNSTRING, false));
            if (Pointer.nativeValue(pnd) == 0l){ // if (pnd == NULL)
                throw new Exception("Problem opening NFC reader.");
            }
            if (NFCLib.INSTANCE.nfc_initiator_init(pnd) < 0) {
                throw new Exception("Failed initiator init.");
            }
            //println("NFC reader:", NFCLib.INSTANCE.nfc_device_get_name(pnd));
            nd_list.add(pnd);
        }
    }

    public int get_num_readers(){
        return num_readers;
    }

    public LibNFC.card_id get_card_id(int reader) throws Exception {
        LibNFC.nfc_target nt = new LibNFC.nfc_target();

        if (NFCLib.INSTANCE.nfc_initiator_select_passive_target((Pointer)nd_list.get(reader), DEFAULT_MODULATION, Pointer.NULL, 0, nt) > 0){
            return new LibNFC.card_id(nt);
        }
        throw new Exception("No card found.");
    }

    public void close(){
        for(int i=0; i<num_readers; ++i)
            NFCLib.INSTANCE.nfc_close((Pointer)nd_list.get(i));
        NFCLib.INSTANCE.nfc_exit(context.getValue());
    }
}

void libNFCTest() {
    try{
        LibNFC mn = new LibNFC();
        println("mn readers:", mn.get_num_readers());
        for(int i=0; i<mn.get_num_readers(); ++i)
            println("mn reader:", i, "serial:", mn.get_card_id(i));
        mn.close();
    }catch(Exception e){
        println(e.getMessage());
    }
    exit();
}

static final int NFC_BUFSIZE_CONNSTRING = 1024;
static final int DEVICE_NAME_LENGTH = 256;
static final int DEVICE_PORT_LENGTH = 64;
static final int MAX_READERS = 10;
static final int NFC_ENOTSUCHDEV = -4;
static final int NFC_EIO = -1;
static final int NFC_PROPERTY_INFINITE_SELECT = 7;

static final long DEFAULT_MODULATION = 0x100000001l;

public interface NFCLib extends Library {
    NFCLib INSTANCE = (NFCLib)Native.loadLibrary("nfc", NFCLib.class);

    public void nfc_init(PointerByReference context);
    public Pointer nfc_open(Pointer context, String connstring);
    public int nfc_initiator_init(Pointer p);

    public int nfc_list_devices(Pointer context, Pointer connstring, int connstring_len);

    int nfc_device_set_property_bool(Pointer pnd, int property, boolean value);

    // list_passive just calls select_passive
    public int nfc_initiator_select_passive_target(Pointer pnd, long nm, Pointer pbtInitData, int szInitData, LibNFC.nfc_target nt);
    public int nfc_initiator_list_passive_targets(Pointer pnd, long nm, LibNFC.nfc_target ant[], long szTargets);

    // list/select_passive blocks for 5 seconds if there is no card.
    public int nfc_initiator_poll_target(Pointer pnd, Pointer pnm, int size_pnm, int PollNr, int uiPeriod, LibNFC.nfc_target nt);

    public String nfc_device_get_name(Pointer p);

    public void nfc_close(Pointer pnd);
    public void nfc_exit(Pointer context);
}

public class LibNFC {
    private PointerByReference context;
    private List<LibNFC.Reader> nd_list;
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

    public class Reader {
        public Pointer pnd;
        public String connstring;
        public Reader(Pointer pnd, String connstring) {
            this.pnd = pnd;
            this.connstring = connstring;
        }
        public LibNFC.card_id get_card_id(){
            LibNFC.nfc_target nt = new LibNFC.nfc_target();

            Memory m = new Memory(100);
            m.setByte((long)0, (byte)1);
            m.setByte((long)4, (byte)1);
            int before = millis();
            //int err = NFCLib.INSTANCE.nfc_initiator_poll_target(pnd, m.share(0), 1, 1, 1, nt);
            int err = NFCLib.INSTANCE.nfc_initiator_select_passive_target(pnd, DEFAULT_MODULATION, Pointer.NULL, 0, nt);
            println("Poll time:", millis() - before);

            if (err > 0){
                //println("card", new LibNFC.card_id(nt));
                return new LibNFC.card_id(nt);
            }
            return new LibNFC.card_id(0);
        }
        public String toString(){
            return connstring;
        }
    }

    public class card_id {
        byte id[];
        public card_id(nfc_target nt) {
            id = new byte[nt.size];
            System.arraycopy(nt.serial, 0, id, 0, nt.size);
        }
        public card_id(int i) {
            id = new byte[i];
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
        max_num_readers = 10;
        context = new PointerByReference();
        NFCLib.INSTANCE.nfc_init(context);
        if (context.getValue() == Pointer.NULL){
            throw new Exception("nfc_init failed.");
        }
        nd_list = new ArrayList();

        Memory connstrings = new Memory(MAX_READERS * NFC_BUFSIZE_CONNSTRING);
        num_readers = NFCLib.INSTANCE.nfc_list_devices(context.getValue(), connstrings.share(0), max_num_readers);
    }

    private LibNFC.Reader connect_reader(String connstring) throws Exception {
        Pointer pnd = NFCLib.INSTANCE.nfc_open(context.getValue(), connstring);
        if (Pointer.nativeValue(pnd) == 0l){ // if (pnd == NULL)
            throw new Exception("Problem opening NFC reader.");
        }
        if (NFCLib.INSTANCE.nfc_initiator_init(pnd) < 0) {
            throw new Exception("Failed initiator init.");
        }
        NFCLib.INSTANCE.nfc_device_set_property_bool(pnd, NFC_PROPERTY_INFINITE_SELECT, false);
        return new LibNFC.Reader(pnd, connstring);
    }

    public void add_unconnected_readers(int current_num_readers, String []connstrings) throws Exception{
        for (String conn: connstrings) {
            boolean found = false;
            for (LibNFC.Reader r : nd_list) {
                if (conn.equals(r.connstring)){
                    found = true;
                    break;
                }
            }
            if (!found) {
                nd_list.add(connect_reader(conn));
            }
        }
    }

    public void disconnect_unconnected_readers(int current_num_readers, String []connstrings){
        Iterator<LibNFC.Reader> loop = nd_list.iterator();
        while (loop.hasNext()){
            LibNFC.Reader r = loop.next();
            boolean found = false;
            for (String conn : connstrings) {
                if (conn.equals(r.connstring)){
                    found = true;
                    break;
                }
            }
            if (!found) {
                loop.remove();
            }
        }
    }

    public void connect_to_readers() throws Exception{
        Memory m_connstrings = new Memory(MAX_READERS * NFC_BUFSIZE_CONNSTRING);
        int current_num_readers = NFCLib.INSTANCE.nfc_list_devices(context.getValue(), m_connstrings.share(0), max_num_readers);

        String []connstrings = new String[current_num_readers];
        for (int i = 0; i < current_num_readers; ++i){
            connstrings[i] = m_connstrings.getString(i*NFC_BUFSIZE_CONNSTRING, false);
        }

        add_unconnected_readers(current_num_readers, connstrings);
        disconnect_unconnected_readers(current_num_readers, connstrings);

        num_readers = current_num_readers;
        if (num_readers != nd_list.size())
            println("Error - num_readers != nd_list.size()", num_readers, nd_list.size());
    }

    public int get_num_readers(){
        return num_readers;
    }

    public void close(){
        for(int i=0; i<num_readers; ++i)
            NFCLib.INSTANCE.nfc_close(nd_list.get(i).pnd);
        NFCLib.INSTANCE.nfc_exit(context.getValue());
    }
}

class LibNFCMainThread extends Thread {
    LibNFC nfc;
    int start;
    ArrayList<LibNFCQueryThread> threads;
    CardReader card_reader;
    public LibNFCMainThread (LibNFC n, CardReader c){
        nfc = n;
        card_reader = c;
        threads = new ArrayList<LibNFCQueryThread>();
    }
    void run() {
        while (true) {
            try{
                nfc.connect_to_readers();
            } catch (Exception e) {
                println("Lib error connecting to readers: " + e);
                break;
            }
            // start threads that need to start
            for (LibNFC.Reader r : nfc.nd_list) {
                boolean found = false;

                for (LibNFCQueryThread t : threads) {
                    if (t.reader == r){
                        found = true;
                        break;
                    }
                }

                if (!found) {
                    LibNFCQueryThread t = new LibNFCQueryThread(nfc, r, card_reader);
                    t.start();
                    threads.add(t);
                    println("Added thread for", r);
                }
            }
            // stop threads that need to stop
            for (LibNFCQueryThread t : threads) {
                if (!nfc.nd_list.contains(t.reader) && t.running == true) {
                    println("Quit thread for", t.reader);
                    t.quit();
                    // remove t from threads
                }
            }
            try{
                sleep(100);
            } catch(Exception e){
                println("Sleep in LibNFCMainThread failed.");
            }
        }
    }
}

class LibNFCQueryThread extends Thread {
    LibNFC.Reader reader;
    boolean running;
    LibNFC.card_id old_cid;
    LibNFC.card_id zero_cid;
    CardReader card_reader;

    LibNFCQueryThread (LibNFC nfc, LibNFC.Reader r, CardReader cr) {
        reader = r;
        zero_cid = old_cid = nfc.new card_id(0);
        card_reader = cr;
    }
    void start () {
        running = true;
        super.start();
    }
    void run () {
        while (running) {
            LibNFC.card_id cid = reader.get_card_id();

            if (!Arrays.equals(cid.id, old_cid.id)){
                if (Arrays.equals(cid.id, zero_cid.id))
                    card_reader.cardRemoved(reader.connstring, old_cid);
                else
                    card_reader.cardAdded(reader.connstring, cid);
                //println("Card changed:", reader, cid);
            }
            old_cid = cid;
        }
    }
    void quit() {
        running = false;
        interrupt();
    }
}

interface CardReader {
    public void cardAdded(String reader, LibNFC.card_id cid);
    public void cardRemoved(String reader, LibNFC.card_id cid);
}

void libNFCTest() {
    LibNFC n;

    CardReader cr = new CardReader() {
        public void cardAdded(String reader, LibNFC.card_id cid) { println(reader, "added card", cid); }
        public void cardRemoved(String reader, LibNFC.card_id cid) { println(reader, "card removed:", cid); }
    };


    try{
        n = new LibNFC();
        LibNFCMainThread t = new LibNFCMainThread(n, cr);
        t.start();
    }catch(Exception e){
        println(e.getMessage());
    }
}

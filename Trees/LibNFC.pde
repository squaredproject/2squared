static final int NFC_BUFSIZE_CONNSTRING = 1024;
static final int DEVICE_NAME_LENGTH = 256;
static final int DEVICE_PORT_LENGTH = 64;
static final int MAX_USER_DEFINED_DEVICES = 4;

interface LibNFC extends Library {
  LibNFC INSTANCE = (LibNFC)Native.loadLibrary("NFC", LibNFC.class);
  
  void nfc_init(PointerByReference context);
//NFC_EXPORT void nfc_init(nfc_context **context) ATTRIBUTE_NONNULL(1);
//00087 NFC_EXPORT void nfc_exit(nfc_context *context) ATTRIBUTE_NONNULL(1);
//00088 NFC_EXPORT int nfc_register_driver(const nfc_driver *driver);
//00089 
//00090 /* NFC Device/Hardware manipulation */
  //nfc_device nfc_open(Pointer context, Pointer connstring);
  Pointer nfc_open(Pointer context, Pointer connstring);
//00091 NFC_EXPORT nfc_device *nfc_open(nfc_context *context, const nfc_connstring connstring) ATTRIBUTE_NONNULL(1);
//00092 NFC_EXPORT void nfc_close(nfc_device *pnd);
//00093 NFC_EXPORT int nfc_abort_command(nfc_device *pnd);
//00094 NFC_EXPORT size_t nfc_list_devices(nfc_context *context, nfc_connstring connstrings[], size_t connstrings_len) ATTRIBUTE_NONNULL(1);
//00095 NFC_EXPORT int nfc_idle(nfc_device *pnd);
//00096 
//00097 /* NFC initiator: act as "reader" */
//00098 NFC_EXPORT int nfc_initiator_init(nfc_device *pnd);
  int nfc_initiator_init(Pointer p);
//00099 NFC_EXPORT int nfc_initiator_init_secure_element(nfc_device *pnd);
//00100 NFC_EXPORT int nfc_initiator_select_passive_target(nfc_device *pnd, const nfc_modulation nm, const uint8_t *pbtInitData, const size_t szInitData, nfc_target *pnt);
  //int nfc_initiator_select_passive_target(Pointer pnd, long nm, Pointer pbtInitData, long szInitData, nfc_target p);
  int nfc_initiator_select_passive_target(Pointer pnd, long nm, Pointer pbtInitData, long szInitData, Memory nt);
//00101 NFC_EXPORT int nfc_initiator_list_passive_targets(nfc_device *pnd, const nfc_modulation nm, nfc_target ant[], const size_t szTargets);
//00102 NFC_EXPORT int nfc_initiator_poll_target(nfc_device *pnd, const nfc_modulation *pnmTargetTypes, const size_t szTargetTypes, const uint8_t uiPollNr, const uint8_t uiPeriod, nfc_target *pnt);
//00103 NFC_EXPORT int nfc_initiator_select_dep_target(nfc_device *pnd, const nfc_dep_mode ndm, const nfc_baud_rate nbr, const nfc_dep_info *pndiInitiator, nfc_target *pnt, const int timeout);
//00104 NFC_EXPORT int nfc_initiator_poll_dep_target(nfc_device *pnd, const nfc_dep_mode ndm, const nfc_baud_rate nbr, const nfc_dep_info *pndiInitiator, nfc_target *pnt, const int timeout);
//00105 NFC_EXPORT int nfc_initiator_deselect_target(nfc_device *pnd);
//00106 NFC_EXPORT int nfc_initiator_transceive_bytes(nfc_device *pnd, const uint8_t *pbtTx, const size_t szTx, uint8_t *pbtRx, const size_t szRx, int timeout);
//00107 NFC_EXPORT int nfc_initiator_transceive_bits(nfc_device *pnd, const uint8_t *pbtTx, const size_t szTxBits, const uint8_t *pbtTxPar, uint8_t *pbtRx, const size_t szRx, uint8_t *pbtRxPar);
//00108 NFC_EXPORT int nfc_initiator_transceive_bytes_timed(nfc_device *pnd, const uint8_t *pbtTx, const size_t szTx, uint8_t *pbtRx, const size_t szRx, uint32_t *cycles);
//00109 NFC_EXPORT int nfc_initiator_transceive_bits_timed(nfc_device *pnd, const uint8_t *pbtTx, const size_t szTxBits, const uint8_t *pbtTxPar, uint8_t *pbtRx, const size_t szRx, uint8_t *pbtRxPar, uint32_t *cycles);
//00110 NFC_EXPORT int nfc_initiator_target_is_present(nfc_device *pnd, const nfc_target *pnt);
//00111 
//00112 /* NFC target: act as tag (i.e. MIFARE Classic) or NFC target device. */
//00113 NFC_EXPORT int nfc_target_init(nfc_device *pnd, nfc_target *pnt, uint8_t *pbtRx, const size_t szRx, int timeout);
//00114 NFC_EXPORT int nfc_target_send_bytes(nfc_device *pnd, const uint8_t *pbtTx, const size_t szTx, int timeout);
//00115 NFC_EXPORT int nfc_target_receive_bytes(nfc_device *pnd, uint8_t *pbtRx, const size_t szRx, int timeout);
//00116 NFC_EXPORT int nfc_target_send_bits(nfc_device *pnd, const uint8_t *pbtTx, const size_t szTxBits, const uint8_t *pbtTxPar);
//00117 NFC_EXPORT int nfc_target_receive_bits(nfc_device *pnd, uint8_t *pbtRx, const size_t szRx, uint8_t *pbtRxPar);
//00118 
//00119 /* Error reporting */
//00120 NFC_EXPORT const char *nfc_strerror(const nfc_device *pnd);
//00121 NFC_EXPORT int nfc_strerror_r(const nfc_device *pnd, char *buf, size_t buflen);
//00122 NFC_EXPORT void nfc_perror(const nfc_device *pnd, const char *s);
//00123 NFC_EXPORT int nfc_device_get_last_error(const nfc_device *pnd);
//00124 
//00125 /* Special data accessors */
//00126 NFC_EXPORT const char *nfc_device_get_name(nfc_device *pnd);
    String nfc_device_get_name(Pointer p);
//00127 NFC_EXPORT const char *nfc_device_get_connstring(nfc_device *pnd);
//00128 NFC_EXPORT int nfc_device_get_supported_modulation(nfc_device *pnd, const nfc_mode mode,  const nfc_modulation_type **const supported_mt);
//00129 NFC_EXPORT int nfc_device_get_supported_baud_rate(nfc_device *pnd, const nfc_modulation_type nmt, const nfc_baud_rate **const supported_br);
//00130 
//00131 /* Properties accessors */
//00132 NFC_EXPORT int nfc_device_set_property_int(nfc_device *pnd, const nfc_property property, const int value);
//00133 NFC_EXPORT int nfc_device_set_property_bool(nfc_device *pnd, const nfc_property property, const bool bEnable);
//00134 
//00135 /* Misc. functions */
//00136 NFC_EXPORT void iso14443a_crc(uint8_t *pbtData, size_t szLen, uint8_t *pbtCrc);
//00137 NFC_EXPORT void iso14443a_crc_append(uint8_t *pbtData, size_t szLen);
//00138 NFC_EXPORT void iso14443b_crc(uint8_t *pbtData, size_t szLen, uint8_t *pbtCrc);
//00139 NFC_EXPORT void iso14443b_crc_append(uint8_t *pbtData, size_t szLen);
//00140 NFC_EXPORT uint8_t *iso14443a_locate_historical_bytes(uint8_t *pbtAts, size_t szAts, size_t *pszTk);
//00141 
//00142 NFC_EXPORT void nfc_free(void *p);
//00143 NFC_EXPORT const char *nfc_version(void);
//00144 NFC_EXPORT int nfc_device_get_information_about(nfc_device *pnd, char **buf);
//00145 
//00146 /* String converter functions */
//00147 NFC_EXPORT const char *str_nfc_modulation_type(const nfc_modulation_type nmt);
//00148 NFC_EXPORT const char *str_nfc_baud_rate(const nfc_baud_rate nbr);
//00149 NFC_EXPORT int str_nfc_target(char **buf, const nfc_target *pnt, bool verbose);
//00150 
//00151 /* Error codes */
//00156 #define NFC_SUCCESS      0
//00157 
//00161 #define NFC_EIO       -1
//00162 
//00166 #define NFC_EINVARG     -2
//00167 
//00171 #define NFC_EDEVNOTSUPP     -3
//00172 
//00176 #define NFC_ENOTSUCHDEV     -4
//00177 
//00181 #define NFC_EOVFLOW     -5
//00182 
//00186 #define NFC_ETIMEOUT      -6
//00187 
//00191 #define NFC_EOPABORTED      -7
//00192 
//00196 #define NFC_ENOTIMPL      -8
//00197 
//00201 #define NFC_ETGRELEASED     -10
//00202 
//00206 #define NFC_ERFTRANS      -20
//00207 
//00211 #define NFC_EMFCAUTHFAIL    -30
//00212 
//00216 #define NFC_ESOFT     -80
//00217 
//00221 #define NFC_ECHIP     -90
  
}

public class nfc_user_defined_device extends Structure {
  public String name;
  public char[] connstring;
  public boolean optional;
  
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "name", "connstring", "optional" });
  }
}

public class nfc_context extends Structure {
  public boolean allow_autoscan;
  public boolean allow_intrusive_scan;
  public int log_level;
  public nfc_user_defined_device[] user_defined_devices;
  public int user_defined_device_count;
  
  public nfc_context() {
    user_defined_devices = new nfc_user_defined_device[4];
  }
  
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "allow_autoscan", "allow_intrusive_scan", "log_level", "user_defined_devices", "user_defined_device_count" });
  }
}

public class nfc_device extends Structure {
  //public nfc_context context;
  public Pointer context;
  public Pointer driver;
  public Pointer driver_data;
  public Pointer chip_data;
  public char[] name;
  public char[] connstring;
  public boolean bCrc;
  public boolean bPar;
  public boolean bEasyFraming;
  public boolean bInfiniteSelect;
  public boolean bAutoIso14443_4;
  public byte btSupportByte;
  public int last_error;
  
  public nfc_device() {
    name = new char[DEVICE_NAME_LENGTH];
    connstring = new char[NFC_BUFSIZE_CONNSTRING];
  }
  
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "context", "driver", "driver_data", "chip_data",
      "name", "connstring", "bCrc", "bPar", "bEasyFraming", "bInfiniteSelect", "bAutoIso14443_4",
      "btSupportByte", "last_error" });
  }
}

public class nfc_modulation extends Structure {
    public int nmt; // nfc_modulation_type nmt;
    public int nbr; // nfc_baud_rate nbr;
    protected List getFieldOrder() {
      return Arrays.asList(new String[] {"nmt", "nbr"});
    }
}

public class nfc_iso14443a_info extends Structure {
  public byte abtAtqa[];
  public byte btSak;
  public long szUidLen;
  public byte abtUid[];
  public long szAtsLen;
  public byte abtAts[]; // Maximal theoretical ATS is FSD-2, FSD=256 for FSDI=8 in RATS

  public nfc_iso14443a_info() {
    abtAtqa = new byte[2];
    abtUid = new byte[10];
    abtAts = new byte[254];
  }

  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "abtAtqa", "btSak", "szUidLen", "abtUid", "szAtsLen", "abtAts"});
  }
}

public class nfc_felica_info {
  public long  szLen;
  public byte  btResCode;
  public byte  abtId[];
  public byte  abtPad[];
  public byte  abtSysCode[];
  public nfc_felica_info() {
    abtId = new byte[8];
    abtPad = new byte[8];
    abtSysCode = new byte[2];
  }
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "szLen", "btResCode", "abtId", "abtPad", "abtSysCode"});
  }
}

public class nfc_iso14443b_info {
  public byte abtPupi[];
  public byte abtApplicationData[];
  public byte abtProtocolInfo[];
  public byte ui8CardIdentifier;
  public nfc_iso14443b_info() {
    abtPupi = new byte[4];
    abtApplicationData = new byte[4];
    abtProtocolInfo = new byte[3];
  }
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "abtPupi", "abtApplicationData", "abtProtocolInfo", "ui8CardIdentifier"});
  }
}

public class nfc_iso14443bi_info {
  public byte abtDIV[];
  public byte btVerLog;
  public byte btConfig;
  public long szAtrLen;
  public byte  abtAtr[];
  public nfc_iso14443bi_info(){
    abtDIV = new byte[4];
    abtAtr = new byte[33];
  }
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "abtDIV", "btVerLog", "btConfig", "szAtrLen", "abtAtr" });
  }
}

public class nfc_iso14443b2sr_info {
  public byte abtUID[];
  public nfc_iso14443b2sr_info() {
    abtUID = new byte[8];
  }
/*
  protected List getFieldOrder() {
    return Arrays.asList(new String[] {});
  }
*/
}

public class nfc_iso14443b2ct_info {
  public byte abtUID[];
  public byte btProdCode;
  public byte btFabCode;
  public nfc_iso14443b2ct_info() {
    abtUID = new byte[4];
  }
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "abtUID", "btProdCode", "btFabCode" });
  }
}

public class nfc_jewel_info {
  public byte  btSensRes[];
  public byte  btId[];
  public nfc_jewel_info(){
    btSensRes = new byte[2];
    btId = new byte[4];
  }
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "btSensRes", "btId" });
  }
}

public class nfc_dep_info {
  public byte  abtNFCID3[];
  public byte  btDID;
  public byte  btBS;
  public byte  btBR;
  public byte  btTO;
  public byte  btPP;
  public byte  abtGB[];
  public long  szGB;
  //nfc_dep_mode ndm;
  public int ndm;
  public nfc_dep_info(){
    abtNFCID3 = new byte[10];
    abtGB = new byte[48];
  }
  protected List getFieldOrder() {
    return Arrays.asList(new String[] { "abtNFCID3", "btDID", "btBS", "btBR", "btTO", "btPP", "abtGB", "szGB", "ndm" });
  }
}

public class nfc_target_info extends Structure {
  public nfc_iso14443a_info nai;
  public nfc_felica_info nfi;
  public nfc_iso14443b_info nbi;
  public nfc_iso14443bi_info nii;
  public nfc_iso14443b2sr_info nsi;
  public nfc_iso14443b2ct_info nci;
  public nfc_jewel_info nji;
  public nfc_dep_info ndi;
  //public nfc_target_info() {
  //  nai = new nfc_i
  //}
  protected List getFieldOrder() {
    return Arrays.asList(new String[] {"nai", "nfi", "nbi", "nii", "nsi", "nci", "nji", "ndi"});
  }
}

public class nfc_target extends Structure {
    public nfc_target_info nti;
    public nfc_modulation nm;
    protected List getFieldOrder() {
      return Arrays.asList(new String[] {"nti", "nm"});
    }
}

void libNFCTest() {
  //nfc_device pnd;
  Pointer pnd;
  //nfc_device pnd = new nfc_device();
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

  Memory nt = new Memory(292);

  if (LibNFC.INSTANCE.nfc_initiator_select_passive_target(pnd, 0x100000001l, Pointer.NULL, 0, nt) > 0){
    println("found");
    System.out.printf("len: %d\n", nt.getByte(3));
    for(int j=0; j<nt.getByte(3); ++j){
        System.out.printf("%0x ", nt.getByte(11+j));
    }
    System.out.println();
  } else {
    println("No card");
  }
  //  if (nfc_initiator_select_passive_target(pnd, nmMifare, NULL, 0, &nt) > 0) {
}

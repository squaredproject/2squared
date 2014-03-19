
/**
 * This defines the positions of the trees, which are
 * x (left to right), z (front to back), and rotation
 * in degrees.
 */
final static float[][] TREE_POSITIONS = {
  /*  X-pos    Y-pos    Rot */
  {  15*FEET, 15*FEET,   0  },
  {  90*FEET, 15*FEET, -45  }
};

/**
 * This defines the mapping of all the clusters. Format
 * specified below. Contains an IP address, tree,
 * level, face, horizontal offset, and mounting.
 *
 * The horizontal offset is specified in inches from the
 * center of the face, so it may be positive or negative.
 *
 * The mounting is a vertical offset. Typically you use
 * a constant CHAIN or BOLT for standard mountings. For
 * non-standard mountings, a custom value may be supplied.
 */ 
final static CP[] CLUSTER_POSITIONS = {
  /*         IP       Tree  Face       Level Offset Mount */
  new CP("10.0.0.105", A, FRONT,         5,    0,   CHAIN),
  new CP("10.0.0.106", A, FRONT_RIGHT,   5,    0,   CHAIN),
  new CP("10.0.0.107", A, RIGHT,         5,    0,   CHAIN),
  new CP("10.0.0.108", A, REAR_RIGHT,    5,    0,   CHAIN),
  new CP("10.0.0.109", A, REAR,          5,    0,   CHAIN),
  new CP("10.0.0.110", A, REAR_LEFT,     5,    0,   CHAIN),
  new CP("10.0.0.111", A, LEFT,          5,    0,   CHAIN),
  new CP("10.0.0.112", A, FRONT_LEFT,    5,    0,   CHAIN),
  
  new CP("10.0.0.113", A, FRONT,         7,  -20,   CHAIN),
  new CP("10.0.0.114", A, FRONT,         7,   20,   CHAIN),
  new CP("10.0.0.115", A, RIGHT,         7,  -20,   CHAIN),
  new CP("10.0.0.116", A, RIGHT,         7,   20,   CHAIN),
  new CP("10.0.0.117", A, REAR,          7,  -20,   CHAIN),
  new CP("10.0.0.118", A, REAR,          7,   20,   CHAIN),
  new CP("10.0.0.119", A, LEFT,          7,  -20,   CHAIN),
  new CP("10.0.0.120", A, LEFT,          7,   20,   CHAIN),
  
  new CP("10.0.0.121", A, FRONT,         9,  -36,   CHAIN),
  new CP("10.0.0.122", A, FRONT,         9,    0,   CHAIN),
  new CP("10.0.0.123", A, FRONT,         9,   36,   CHAIN),
  new CP("10.0.0.124", A, RIGHT,         9,  -36,   CHAIN),
  new CP("10.0.0.125", A, RIGHT,         9,    0,   CHAIN),
  new CP("10.0.0.126", A, RIGHT,         9,   36,   CHAIN),
  new CP("10.0.0.127", A, REAR,          9,  -36,   CHAIN),
  new CP("10.0.0.128", A, REAR,          9,    0,   CHAIN),
  new CP("10.0.0.129", A, REAR,          9,   36,   CHAIN),
  new CP("10.0.0.130", A, LEFT,          9,  -36,   CHAIN),
  new CP("10.0.0.131", A, LEFT,          9,    0,   CHAIN),
  new CP("10.0.0.132", A, LEFT,          9,   36,   CHAIN),
  
  new CP("10.0.0.133", A, FRONT,        11,  -24,   CHAIN),
  new CP("10.0.0.134", A, FRONT,        11,   24,   CHAIN),
  new CP("10.0.0.135", A, FRONT_RIGHT,  11,    0,   CHAIN),
  new CP("10.0.0.136", A, RIGHT,        11,  -24,   CHAIN),
  new CP("10.0.0.137", A, RIGHT,        11,   24,   CHAIN),
  new CP("10.0.0.138", A, REAR_RIGHT,   11,    0,   CHAIN),
  new CP("10.0.0.139", A, REAR,         11,  -24,   CHAIN),
  new CP("10.0.0.140", A, REAR,         11,   24,   CHAIN),
  new CP("10.0.0.141", A, REAR_LEFT,    11,    0,   CHAIN),
  new CP("10.0.0.142", A, LEFT,         11,  -24,   CHAIN),
  new CP("10.0.0.143", A, LEFT,         11,   24,   CHAIN),
  new CP("10.0.0.144", A, FRONT_LEFT,   11,    0,   CHAIN),
  
  new CP("10.0.0.145", A, FRONT,        13,    0,   CHAIN),
  new CP("10.0.0.146", A, FRONT_RIGHT,  13,    0,   CHAIN),
  new CP("10.0.0.147", A, RIGHT,        13,    0,   CHAIN),
  new CP("10.0.0.148", A, REAR_RIGHT,   13,    0,   CHAIN),
  new CP("10.0.0.149", A, REAR,         13,    0,   CHAIN),
  new CP("10.0.0.150", A, REAR_LEFT,    13,    0,   CHAIN),
  new CP("10.0.0.151", A, LEFT,         13,    0,   CHAIN),
  new CP("10.0.0.152", A, FRONT_LEFT,   13,    0,   CHAIN),
  
// new CP("10.0.0.153", A, FRONT_LEFT,   13,    0,   CHAIN),
  
  
  new CP("10.0.0.205", B, FRONT,         5,    0,   CHAIN),
  new CP("10.0.0.206", B, FRONT_RIGHT,   5,    0,   CHAIN),
  new CP("10.0.0.207", B, RIGHT,         5,    0,   CHAIN),
  new CP("10.0.0.208", B, REAR_RIGHT,    5,    0,   CHAIN),
  new CP("10.0.0.209", B, REAR,          5,    0,   CHAIN),
  new CP("10.0.0.210", B, REAR_LEFT,     5,    0,   CHAIN),
  new CP("10.0.0.211", B, LEFT,          5,    0,   CHAIN),
  new CP("10.0.0.212", B, FRONT_LEFT,    5,    0,   CHAIN),
  
  new CP("10.0.0.213", B, FRONT,         7,  -20,   CHAIN),
  new CP("10.0.0.214", B, FRONT,         7,   20,   CHAIN),
  new CP("10.0.0.215", B, RIGHT,         7,  -20,   CHAIN),
  new CP("10.0.0.216", B, RIGHT,         7,   20,   CHAIN),
  new CP("10.0.0.217", B, REAR,          7,  -20,   CHAIN),
  new CP("10.0.0.218", B, REAR,          7,   20,   CHAIN),
  new CP("10.0.0.219", B, LEFT,          7,  -20,   CHAIN),
  new CP("10.0.0.220", B, LEFT,          7,   20,   CHAIN),
  
  new CP("10.0.0.221", B, FRONT,         9,  -36,   CHAIN),
  new CP("10.0.0.222", B, FRONT,         9,    0,   CHAIN),
  new CP("10.0.0.223", B, FRONT,         9,   36,   CHAIN),
  new CP("10.0.0.224", B, RIGHT,         9,  -36,   CHAIN),
  new CP("10.0.0.225", B, RIGHT,         9,    0,   CHAIN),
  new CP("10.0.0.226", B, RIGHT,         9,   36,   CHAIN),
  new CP("10.0.0.227", B, REAR,          9,  -36,   CHAIN),
  new CP("10.0.0.228", B, REAR,          9,    0,   CHAIN),
  new CP("10.0.0.229", B, REAR,          9,   36,   CHAIN),
  new CP("10.0.0.230", B, LEFT,          9,  -36,   CHAIN),
  new CP("10.0.0.231", B, LEFT,          9,    0,   CHAIN),
  new CP("10.0.0.232", B, LEFT,          9,   36,   CHAIN),
  
  new CP("10.0.0.233", B, FRONT,        11,  -24,   CHAIN),
  new CP("10.0.0.234", B, FRONT,        11,   24,   CHAIN),
  new CP("10.0.0.235", B, FRONT_RIGHT,  11,    0,   CHAIN),
  new CP("10.0.0.236", B, RIGHT,        11,  -24,   CHAIN),
  new CP("10.0.0.237", B, RIGHT,        11,   24,   CHAIN),
  new CP("10.0.0.238", B, REAR_RIGHT,   11,    0,   CHAIN),
  new CP("10.0.0.239", B, REAR,         11,  -24,   CHAIN),
  new CP("10.0.0.240", B, REAR,         11,   24,   CHAIN),
  new CP("10.0.0.241", B, REAR_LEFT,    11,    0,   CHAIN),
  new CP("10.0.0.242", B, LEFT,         11,  -24,   CHAIN),
  new CP("10.0.0.243", B, LEFT,         11,   24,   CHAIN),
  new CP("10.0.0.244", B, FRONT_LEFT,   11,    0,   CHAIN),
  
  new CP("10.0.0.245", B, FRONT,        13,    0,   CHAIN),
  new CP("10.0.0.246", B, FRONT_RIGHT,  13,    0,   CHAIN),
  new CP("10.0.0.247", B, RIGHT,        13,    0,   CHAIN),
  new CP("10.0.0.248", B, REAR_RIGHT,   13,    0,   CHAIN),
  new CP("10.0.0.249", B, REAR,         13,    0,   CHAIN),
  new CP("10.0.0.250", B, REAR_LEFT,    13,    0,   CHAIN),
  new CP("10.0.0.251", B, LEFT,         13,    0,   CHAIN),
  new CP("10.0.0.252", B, FRONT_LEFT,   13,    0,   CHAIN),
  
// new CP("10.0.0.253", B, FRONT_LEFT,   13,    0,   CHAIN),
  
};

/**
 * =====================================================
 * NOTHING BELOW THIS POINT SHOULD REQUIRE MODIFICATION!
 * =====================================================
 */

static class CP {
  final String ipAddress;
  final int treeIndex;
  final int face;
  final int level;
  final float offset;
  final float mountPoint;
  
  CP(String ipAddress, int treeIndex, int face, int level, float offset, float mountPoint) {
    this.ipAddress = ipAddress;
    this.treeIndex = treeIndex;
    this.face = face;
    this.level = level;
    this.offset = offset;
    this.mountPoint = mountPoint;
  }
}



/**
 * This defines the positions of the trees, which are
 * x (left to right), z (front to back), and rotation
 * in degrees.
 */
final static float[][] TREE_POSITIONS = {
  /*  X-pos    Y-pos    Rot */
  {  
    15*FEET, 15*FEET, 0
  }
  , 
  {  
    90*FEET, 15*FEET, -45
  }
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
  new CP("10.0.0.105", A, FRONT, 5, 0, CHAIN), 
  new CP("10.0.0.106", A, FRONT_RIGHT, 5, 0, CHAIN), 
  new CP("10.0.0.107", A, RIGHT, 5, 0, CHAIN), 
  new CP("10.0.0.108", A, REAR_RIGHT, 5, 0, CHAIN), 
  new CP("10.0.0.109", A, REAR, 5, 0, CHAIN), 
  new CP("10.0.0.110", A, REAR_LEFT, 5, 0, CHAIN), 
  new CP("10.0.0.111", A, LEFT, 5, 0, CHAIN), 
  new CP("10.0.0.112", A, FRONT_LEFT, 5, 0, CHAIN), 

  new CP("10.0.0.113", A, FRONT, 7, -20, CHAIN), 
  new CP("10.0.0.114", A, FRONT, 7, 20, CHAIN), 
  new CP("10.0.0.115", A, RIGHT, 7, -20, CHAIN), 
  new CP("10.0.0.116", A, RIGHT, 7, 20, CHAIN), 
  new CP("10.0.0.117", A, REAR, 7, -20, CHAIN), 
  new CP("10.0.0.118", A, REAR, 7, 20, CHAIN), 
  new CP("10.0.0.119", A, LEFT, 7, -20, CHAIN), 
  new CP("10.0.0.120", A, LEFT, 7, 20, CHAIN), 

  new CP("10.0.0.121", A, FRONT, 9, -36, CHAIN), 
  new CP("10.0.0.122", A, FRONT, 9, 0, CHAIN), 
  new CP("10.0.0.123", A, FRONT, 9, 36, CHAIN), 
  new CP("10.0.0.124", A, RIGHT, 9, -36, CHAIN), 
  new CP("10.0.0.125", A, RIGHT, 9, 0, CHAIN), 
  new CP("10.0.0.126", A, RIGHT, 9, 36, CHAIN), 
  new CP("10.0.0.127", A, REAR, 9, -36, CHAIN), 
  new CP("10.0.0.128", A, REAR, 9, 0, CHAIN), 
  new CP("10.0.0.129", A, REAR, 9, 36, CHAIN), 
  new CP("10.0.0.130", A, LEFT, 9, -36, CHAIN), 
  new CP("10.0.0.131", A, LEFT, 9, 0, CHAIN), 
  new CP("10.0.0.132", A, LEFT, 9, 36, CHAIN), 

  new CP("10.0.0.133", A, FRONT, 11, -24, CHAIN), 
  new CP("10.0.0.134", A, FRONT, 11, 24, CHAIN), 
  new CP("10.0.0.135", A, FRONT_RIGHT, 11, 0, CHAIN), 
  new CP("10.0.0.136", A, RIGHT, 11, -24, CHAIN), 
  new CP("10.0.0.137", A, RIGHT, 11, 24, CHAIN), 
  new CP("10.0.0.138", A, REAR_RIGHT, 11, 0, CHAIN), 
  new CP("10.0.0.139", A, REAR, 11, -24, CHAIN), 
  new CP("10.0.0.140", A, REAR, 11, 24, CHAIN), 
  new CP("10.0.0.141", A, REAR_LEFT, 11, 0, CHAIN), 
  new CP("10.0.0.142", A, LEFT, 11, -24, CHAIN), 
  new CP("10.0.0.143", A, LEFT, 11, 24, CHAIN), 
  new CP("10.0.0.144", A, FRONT_LEFT, 11, 0, CHAIN), 

  new CP("10.0.0.145", A, FRONT, 13, 0, CHAIN), 
  new CP("10.0.0.146", A, FRONT_RIGHT, 13, 0, CHAIN), 
  new CP("10.0.0.147", A, RIGHT, 13, 0, CHAIN), 
  new CP("10.0.0.148", A, REAR_RIGHT, 13, 0, CHAIN), 
  new CP("10.0.0.149", A, REAR, 13, 0, CHAIN), 
  new CP("10.0.0.150", A, REAR_LEFT, 13, 0, CHAIN), 
  new CP("10.0.0.151", A, LEFT, 13, 0, CHAIN), 
  new CP("10.0.0.152", A, FRONT_LEFT, 13, 0, CHAIN), 

  // new CP("10.0.0.153", A, FRONT_LEFT,   13,    0,   CHAIN),


  new CP("10.0.0.205", B, FRONT, 5, 0, CHAIN), 
  new CP("10.0.0.206", B, FRONT_RIGHT, 5, 0, CHAIN), 
  new CP("10.0.0.207", B, RIGHT, 5, 0, CHAIN), 
  new CP("10.0.0.208", B, REAR_RIGHT, 5, 0, CHAIN), 
  new CP("10.0.0.209", B, REAR, 5, 0, CHAIN), 
  new CP("10.0.0.210", B, REAR_LEFT, 5, 0, CHAIN), 
  new CP("10.0.0.211", B, LEFT, 5, 0, CHAIN), 
  new CP("10.0.0.212", B, FRONT_LEFT, 5, 0, CHAIN), 

  new CP("10.0.0.213", B, FRONT, 7, -20, CHAIN), 
  new CP("10.0.0.214", B, FRONT, 7, 20, CHAIN), 
  new CP("10.0.0.215", B, RIGHT, 7, -20, CHAIN), 
  new CP("10.0.0.216", B, RIGHT, 7, 20, CHAIN), 
  new CP("10.0.0.217", B, REAR, 7, -20, CHAIN), 
  new CP("10.0.0.218", B, REAR, 7, 20, CHAIN), 
  new CP("10.0.0.219", B, LEFT, 7, -20, CHAIN), 
  new CP("10.0.0.220", B, LEFT, 7, 20, CHAIN), 

  new CP("10.0.0.221", B, FRONT, 9, -36, CHAIN), 
  new CP("10.0.0.222", B, FRONT, 9, 0, CHAIN), 
  new CP("10.0.0.223", B, FRONT, 9, 36, CHAIN), 
  new CP("10.0.0.224", B, RIGHT, 9, -36, CHAIN), 
  new CP("10.0.0.225", B, RIGHT, 9, 0, CHAIN), 
  new CP("10.0.0.226", B, RIGHT, 9, 36, CHAIN), 
  new CP("10.0.0.227", B, REAR, 9, -36, CHAIN), 
  new CP("10.0.0.228", B, REAR, 9, 0, CHAIN), 
  new CP("10.0.0.229", B, REAR, 9, 36, CHAIN), 
  new CP("10.0.0.230", B, LEFT, 9, -36, CHAIN), 
  new CP("10.0.0.231", B, LEFT, 9, 0, CHAIN), 
  new CP("10.0.0.232", B, LEFT, 9, 36, CHAIN), 

  new CP("10.0.0.233", B, FRONT, 11, -24, CHAIN), 
  new CP("10.0.0.234", B, FRONT, 11, 24, CHAIN), 
  new CP("10.0.0.235", B, FRONT_RIGHT, 11, 0, CHAIN), 
  new CP("10.0.0.236", B, RIGHT, 11, -24, CHAIN), 
  new CP("10.0.0.237", B, RIGHT, 11, 24, CHAIN), 
  new CP("10.0.0.238", B, REAR_RIGHT, 11, 0, CHAIN), 
  new CP("10.0.0.239", B, REAR, 11, -24, CHAIN), 
  new CP("10.0.0.240", B, REAR, 11, 24, CHAIN), 
  new CP("10.0.0.241", B, REAR_LEFT, 11, 0, CHAIN), 
  new CP("10.0.0.242", B, LEFT, 11, -24, CHAIN), 
  new CP("10.0.0.243", B, LEFT, 11, 24, CHAIN), 
  new CP("10.0.0.244", B, FRONT_LEFT, 11, 0, CHAIN), 

  new CP("10.0.0.245", B, FRONT, 13, 0, CHAIN), 
  new CP("10.0.0.246", B, FRONT_RIGHT, 13, 0, CHAIN), 
  new CP("10.0.0.247", B, RIGHT, 13, 0, CHAIN), 
  new CP("10.0.0.248", B, REAR_RIGHT, 13, 0, CHAIN), 
  new CP("10.0.0.249", B, REAR, 13, 0, CHAIN), 
  new CP("10.0.0.250", B, REAR_LEFT, 13, 0, CHAIN), 
  new CP("10.0.0.251", B, LEFT, 13, 0, CHAIN), 
  new CP("10.0.0.252", B, FRONT_LEFT, 13, 0, CHAIN), 

  // new CP("10.0.0.248", B, FRONT_LEFT,   13,    0,   CHAIN),
};

void dumpClusterJSON(String filename) {
  JSONArray arr = new JSONArray();
  for (CP cp : CLUSTER_POSITIONS) {
    arr.append(new JSONObject()
      .setString("ipAddress", cp.ipAddress)
      .setInt("treeIndex", cp.treeIndex)
      .setInt("face", cp.face)
      .setInt("level", cp.level)
      .setFloat("offset", cp.offset)
      .setFloat("mountPoint", cp.mountPoint)
      );
  }
  saveJSONArray(arr, filename);
}

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

class MappingTool extends LXEffect {

  final DiscreteParameter clusterIndex = new DiscreteParameter("CLUSTER", model.clusters.size()); 
  final BooleanParameter showBlanks = new BooleanParameter("BLANKS", false);

  MappingTool(LX lx) {
    super(lx);
  }
  
  JSONObject getConfig() {
    return clusterConfig.getJSONObject(clusterIndex.getValuei());
  }
  
  Cluster getCluster() {
    return model.clusters.get(clusterIndex.getValuei());
  }

  public void apply(int[] colors) {
    if (isEnabled()) {
      Cluster active = getCluster();
      for (Cluster cluster : model.clusters) {
        for (LXPoint point : cluster.points) {
          colors[point.index] = (cluster == active) ? #ffffff : #000000;
        }
      }
    }
  }
}

class UIMapping extends UIWindow {
  
  final UILabel ipAddress;
  final UIToggleSet tree;
  final UIIntegerBox level;
  final UIToggleSet face;
  final UISlider offset;
  final UISlider mountPoint;
  
  UIMapping(UI ui) {
    super(ui, "CLUSTER TOOL", 4, Trees.this.height - 270, 140, 266);
    
    final UIIntegerBox clusterIndex = new UIIntegerBox().setParameter(mappingTool.clusterIndex);
    
    (ipAddress = new UILabel()).setAlignment(CENTER, CENTER).setBorderColor(#666666).setBackgroundColor(#292929);
    tree = new UIToggleSet() {
      protected void onToggle(String value) {
        mappingTool.getConfig().setInt("treeIndex", (value == "A") ? 0 : 1);
      }
    }.setOptions(new String[] { "A", "B" });
    
    level = new UIIntegerBox() {
      protected void onValueChange(int value) {
        mappingTool.getConfig().setInt("level", value); 
      }
    }.setRange(0, 14);
    
    face = new UIToggleSet() {
      protected void onToggle(String value) {
        mappingTool.getConfig().setInt("face", face.getValueIndex());
      }
    }.setOptions(new String[] { " ", " ", " ", " ", " ", " ", " ", " " });
    
    BasicParameter offsetParameter;
    (offset = new UISlider()).setParameter(offsetParameter = new BasicParameter("OFFSET", 0, -1, 1));
    offsetParameter.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        mappingTool.getConfig().setFloat("offset", parameter.getValuef());
      }
    });
    
    BasicParameter mountPointParameter;
    (mountPoint = new UISlider())
    .setParameter(mountPointParameter = new BasicParameter("MOUNT", CHAIN, CHAIN, BOLT));
    mountPointParameter.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        mappingTool.getConfig().setFloat("mountPoint", parameter.getValuef());
      }
    });
    
    mappingTool.clusterIndex.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        setCluster();
      }
    });
    
    float yPos = TITLE_LABEL_HEIGHT;
    new UIButton(4, yPos, width-8, 20) {
      void onToggle(boolean enabled) {
        if (enabled) {
          clusterIndex.focus();
        }
      }
    }
    .setLabel("MAPPING MODE")
    .setParameter(mappingTool.enabled)
    .addToContainer(this);
    yPos += 24;
    
    // yPos = labelRow(yPos, "BLANKS", new UIButton().setParameter(mappingTool.showBlanks));
    yPos = labelRow(yPos, "CLUSTER #", clusterIndex);
    yPos = labelRow(yPos, "IP", ipAddress);
    yPos = labelRow(yPos, "TREE", tree);
    yPos = labelRow(yPos, "LEVEL", level);
    yPos = labelRow(yPos, "FACE", face);
    yPos = labelRow(yPos, "OFFSET", offset);
    yPos = labelRow(yPos, "MOUNT", mountPoint);
    
    new UIButton(4, yPos, this.width-8, 20) {
      void onToggle(boolean active) {
        if (active) {
          String backupFileName = CLUSTER_CONFIG_FILE + ".backup." + month() + "." + day() + "." + hour() + "." + minute() + "." + second();
          saveBytes(backupFileName, loadBytes(CLUSTER_CONFIG_FILE));
          saveJSONArray(clusterConfig, CLUSTER_CONFIG_FILE);
          setLabel("Saved. Restart needed.");
        }
      }
    }.setMomentary(true).setLabel("Save Changes").addToContainer(this);
    
    setCluster();
  }
  
  float labelRow(float yPos, String label, UIObject obj) {
    new UILabel(4, yPos+5, 50, 20)
    .setLabel(label)
    .addToContainer(this);
    obj
    .setPosition(58, yPos)
    .setSize(width-62, 20)
    .addToContainer(this);
    yPos += 24;
    return yPos;
  }
  
  void setCluster() {
    JSONObject cp = clusterConfig.getJSONObject(mappingTool.clusterIndex.getValuei());
    ipAddress.setLabel(cp.getString("ipAddress"));
    tree.setValue(cp.getInt("treeIndex"));
    level.setValue(cp.getInt("level"));
    face.setValue(cp.getInt("face"));
    offset.getParameter().setValue(cp.getFloat("offset"));
    mountPoint.getParameter().setValue(cp.getFloat("mountPoint"));
  }
}

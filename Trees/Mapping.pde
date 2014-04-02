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

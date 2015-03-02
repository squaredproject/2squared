class MappingTool extends Effect {

  final SinLFO strobe = new SinLFO(20, 100, 1000);
  
  final DiscreteParameter clusterIndex = new DiscreteParameter("CLUSTER", clusterConfig.size()); 
  final BooleanParameter showBlanks = new BooleanParameter("BLANKS", false);

  MappingTool(LX lx) {
    super(lx);
    addModulator(strobe).start();
    addLayer(new MappingLayer());
  }
  
  JSONObject getConfig() {
    return clusterConfig.getJSONObject(clusterIndex.getValuei());
  }
  
  Cluster getCluster() {
    return model.clustersByIp.get(getConfig().getString("ipAddress"));
  }

  public void run(double deltaMs) {
  }
  
  class MappingLayer extends Layer {
    
    MappingLayer() {
      super(MappingTool.this.lx);
    }
    
    public void run(double deltaMs) {
      if (isEnabled()) {
        for (Cube cube : getCluster().cubes) {
          blendColor(cube.index, lx.hsb(0, 0, strobe.getValuef()), LXColor.Blend.ADD);
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
  final UISlider skew;
  
  UIMapping(UI ui) {
    super(ui, "CLUSTER TOOL", 4, Trees.this.height - 244, 140, 240);
    
    final UIIntegerBox clusterIndex = new UIIntegerBox().setParameter(mappingTool.clusterIndex);
    
    (ipAddress = new UILabel()).setAlignment(CENTER, CENTER).setBorderColor(#666666).setBackgroundColor(#292929);
    tree = new UIToggleSet() {
      protected void onToggle(String value) {
        mappingTool.getConfig().setInt("treeIndex", (value == "L") ? 0 : 1);
      }
    }.setOptions(new String[] { "L", "R" });
    
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
    
    BasicParameter skewParameter;
    (skew = new UISlider()).setParameter(skewParameter = new BasicParameter("SKEW", 0, 30, -30));
    skewParameter.addListener(new LXParameterListener() {
      public void onParameterChanged(LXParameter parameter) {
        mappingTool.getConfig().setFloat("skew", parameter.getValuef());
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
    .setInactiveLabel("Disabled")
    .setActiveLabel("Enabled")
    .setParameter(mappingTool.enabled)
    .addToContainer(this);
    yPos += 24;
    
    // yPos = labelRow(yPos, "BLANKS", new UIButton().setParameter(mappingTool.showBlanks));
    yPos = labelRow(yPos, "CLUSTER #", clusterIndex);
    yPos = labelRow(yPos, "IP", ipAddress);
    // yPos = labelRow(yPos, "TREE", tree);
    yPos = labelRow(yPos, "LEVEL", level);
    yPos = labelRow(yPos, "FACE", face);
    yPos = labelRow(yPos, "OFFSET", offset);
    yPos = labelRow(yPos, "MOUNT", mountPoint);
    yPos = labelRow(yPos, "SKEW", skew);
    
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
  
  float labelRow(float yPos, String label, UI2dComponent obj) {
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
    skew.getParameter().setValue(cp.getFloat("skew", 0));
  }
}


DDPDatagram clusterDatagram(Cluster cluster) {
  int[] pointIndices = new int[Cluster.PIXELS_PER_CLUSTER];
  int pi = 0;
  for (Cube cube : cluster.cubes) {
    int numPixels = (cube.size >= Cube.LARGE) ? Cube.PIXELS_PER_LARGE_CUBE : Cube.PIXELS_PER_SMALL_CUBE;
    for (int i = 0; i < numPixels; ++i) {
      pointIndices[pi++] = cube.index;
    }
  }
  return new DDPDatagram(pointIndices);
}

class UIOutput extends UIWindow {
  static final int LIST_NUM_ROWS = 3;
  static final int LIST_ROW_HEIGHT = 20;
  static final int LIST_HEIGHT = LIST_NUM_ROWS * LIST_ROW_HEIGHT;
  static final int BUTTON_HEIGHT = 20;
  static final int SPACER = 8;
  UIOutput(UI ui, float x, float y) {
    super(ui, "LIVE OUTPUT", x, y, 140, UIWindow.TITLE_LABEL_HEIGHT - 1 + BUTTON_HEIGHT + SPACER + LIST_HEIGHT);
    float yPos = UIWindow.TITLE_LABEL_HEIGHT - 2;
    new UIButton(4, yPos, width-8, BUTTON_HEIGHT)
      .setParameter(output.enabled)
      .setActiveLabel("Enabled")
      .setInactiveLabel("Disabled")
      .addToContainer(this);
    yPos += BUTTON_HEIGHT + SPACER;
    
    List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
    for (LXDatagram datagram : datagrams) {
      items.add(new DatagramItem(datagram));
    }
    new UIItemList(1, yPos, width-2, LIST_HEIGHT)
    .setItems(items)
    .setBackgroundColor(#ff0000)
    .addToContainer(this);
  }
  
  class DatagramItem extends UIItemList.AbstractItem {
    
    final LXDatagram datagram;
    
    DatagramItem(LXDatagram datagram) {
      this.datagram = datagram;
      datagram.enabled.addListener(new LXParameterListener() {
        public void onParameterChanged(LXParameter parameter) {
          redraw();
        }
      });
    }
    
    String getLabel() {
      return datagram.getAddress().toString();
    }
    
    boolean isSelected() {
      return datagram.enabled.isOn();
    }
    
    void onMousePressed() {
      datagram.enabled.toggle();
    }
  }
}


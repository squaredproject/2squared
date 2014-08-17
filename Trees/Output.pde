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
  UIOutput(UI ui, float x, float y) {
    super(ui, "LIVE OUTPUT", x, y, 140, 72 + 239);
    float yPos = UIWindow.TITLE_LABEL_HEIGHT - 2;
    new UIButton(4, yPos, width-8, 20)
      .setParameter(output.enabled)
      .setActiveLabel("Enabled")
      .setInactiveLabel("Disabled")
      .addToContainer(this);
    yPos += 28;
    
    List<UIItemList.Item> items = new ArrayList<UIItemList.Item>();
    for (LXDatagram datagram : datagrams) {
      items.add(new DatagramItem(datagram));
    }
    new UIItemList(1, yPos, width-2, 260)
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


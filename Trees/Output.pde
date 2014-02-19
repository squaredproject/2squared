abstract class DDPDatagram extends LXDatagram {
  
  public static final int HEADER_LENGTH = 10;
  
  protected DDPDatagram(int numPixels) {
    super(HEADER_LENGTH + numPixels*3);
    int dataLen = numPixels * 3;
    setPort(4048);
    buffer[0] = 0x41;
    buffer[1] = 0;
    buffer[2] = 0;
    buffer[3] = 1;
    buffer[4] = 0;
    buffer[5] = 0;
    buffer[6] = 0;
    buffer[7] = 0;
    buffer[8] = (byte) (0xff & (dataLen >> 8));
    buffer[9] = (byte) (0xff & dataLen);
  }
}

class DDPSection extends DDPDatagram {
  
  private static final int PIXELS_PER_SECTION = 3*12 + 13*6;
  
  private final Section section;
  
  public DDPSection(Section s) {
    super(PIXELS_PER_SECTION);
    this.section = s;
  }
  
  public void onSend(color[] colors) {
    int i = HEADER_LENGTH;
    for (Cube cube : this.section.cubes) {
      for (LXPoint p : cube.points) {
        color c = colors[p.index]; 
        buffer[i++] = (byte) ((c >> 16) & 0xff);
        buffer[i++] = (byte) ((c >> 8) & 0xff);
        buffer[i++] = (byte) (c  & 0xff);
      }
    }
  }
}


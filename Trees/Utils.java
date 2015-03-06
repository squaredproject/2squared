class Utils {

  static private final long millisOffset = System.currentTimeMillis();

  static public int millis() {
    return (int) (System.currentTimeMillis() - millisOffset);
  }
}

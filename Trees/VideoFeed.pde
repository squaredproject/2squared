//
// We'll add the option for gopro wireless once bugs squashed.
//

import processing.video.*;

class VideoFeed {

  private PApplet parent;
  private Capture vid;

  public VideoFeed(PApplet p) {
    
        //String[] alist = Capture.list();
        //for (String s : alist) { println("cam " + s); }
        
	vid = new Capture(parent=p,320,240,15); // 15 fps

  }

  public int[] pixels() { return vid.pixels; }
  
  public void start() { vid.start();       }
  public void stop()  { vid.stop();        }
  public void fetch() { if (vid.available()) { vid.read(); vid.loadPixels(); }} // update as available...
  public int height() { return vid.height; }
  public int width()  { return vid.width;  }
}



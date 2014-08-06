//
// We'll add the option for gopro wireless once bugs squashed.
//

import processing.video.*;

class VideoFeed {

  private PApplet parent;
  private Capture vid;
  private boolean haveFeed;

  public VideoFeed(PApplet p) {
    
        //String[] alist = Capture.list();
        //for (String s : alist) { println("cam " + s); }

	haveFeed = true;
        
	try {
		vid = new Capture(parent=p,320,240,15); // 15 fps
	} catch(Throwable e) {
		haveFeed = false;
	}

  }

  public int[] pixels() { return haveFeed ? vid.pixels : null; }
  
  public void start() { if (haveFeed) vid.start(); }
  public void stop()  { if (haveFeed) vid.stop(); }
  public void fetch() { if (haveFeed && vid.available()) { vid.read(); vid.loadPixels(); }} // update as available...
  public int height() { return vid.height; }
  public int width()  { return vid.width;  }
}



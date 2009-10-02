class BackgroundArtist {
    color c;
    boolean active = true;
    
    BackgroundArtist() {
	c = #000000;
    }

    void init(Object o) {
	c = ((Integer) o).intValue();
    }

    boolean doesClear() {
	// whether or not the background explicitly clears things first
	return true;
    }

    void setCurrentSource(int i) { }
    
    void setSpeed(float s) { }

    void paint() {
	// draws background
	background(c);
    }
}


class MovieBackgroundArtist extends BackgroundArtist {
    int pvw, pvh;
    // JMC stuff should be a separate class, or subclass eventually
    //JMCMovieGL m;
    int beatTimer = 0;
    Movie m;
    // Preload all movie objects for fast switching hopefully
    Movie movieRepository[];
    // Index of current move
    int vidNum = 0;
    PApplet parent;
    float beatJump = 0.0;
    float speed = 1.0;

    MovieBackgroundArtist(PApplet _parent) {
      parent = _parent;
    }
    
    void setCurrentSource(int i) {
      m.stop();
      if (i < movieRepository.length) {
         m = movieRepository[i];        
      } else {
         m = movieRepository[0];
         println("Movie index out of range");
      }
      m.loop();
    }
    
    void setSpeed(float s) {
      speed = s;
      m.speed(s);
      
    }

    void init(Object o) {
      // Object o is a array of movie filenames

      String movieFiles[] = (String[]) o;
      println("Loading background movies...");
      // load all movies 
      movieRepository = new Movie[movieFiles.length];
      for (int i = 0; i < movieFiles.length; i++) {
         movieRepository[i] = new Movie(parent,movieFiles[i]);
      }
      m = movieRepository[0];
      m.loop();
//      m = (Movie) o;
//      int counter = 0;
    }

    void paint() {
      if (beatJump != 0.0 && beat.isKick()) {
        // JMC
        //m.setCurrentTime(sosMovie.getCurrentTime() - 0.5);
        m.jump(m.time() + beatJump);
      }
      
      // JMC:
      // m.image(gl, 0, 0, width, height);
      
      // Processing Movie library:
      //if (m.available()) m.read();
      image(m, 0, 0, width, height);
      if (m.time() == 0 && speed < 0.0) m.jump(m.duration());
    }

}

class TitleBackgroundArtist extends BackgroundArtist {
    int pvw, pvh;
    // JMC stuff should be a separate class, or subclass eventually
    //JMCMovieGL m;
    //int beatTimer = 0;
    Movie m;
    // Preload all movie objects for fast switching hopefully
    Movie movieRepository[][];
    // Index of current move
    int vidNum = 0;
    int isOverlay = 0; // 1 when oerlay is on, don't replace with boolean! used as idx
    PApplet parent;
    boolean playing = false;
    int changeTo = 0; // because setCurrentSource breaks threading

    TitleBackgroundArtist(PApplet _parent) {
      parent = _parent;
    }
    
    void setCurrentSource(int i) {
        changeTo = i;
    }

    void init(Object o) {
      // Object o is a array of movie filenames

      String movieFiles[][] = (String[][]) o;
      println("Loading titles...");
      // load all movies 
      movieRepository = new Movie[movieFiles.length][];
      for (int i = 0; i < movieFiles.length; i++) {
         movieRepository[i] = new Movie[2];
         if (movieFiles[i][0] != null)
           movieRepository[i][0] = new Movie(parent,"titles/" + movieFiles[i][0]);
         if (movieFiles[i][1] != null)
           movieRepository[i][1] = new Movie(parent,"titles/overlay/" + movieFiles[i][1]);
      }
      vidNum = changeTo = 0;
      isOverlay = 0;
      m = movieRepository[vidNum][isOverlay];
//      m = (Movie) o;
//      int counter = 0;
    }

    void paint() {
      if (movieRepository[vidNum][isOverlay] != m || changeTo != vidNum) {
        int i = changeTo;
        if (debug) println("Changing to title " + changeTo + " (overlay=" + isOverlay + ")");
        stop();
        oscSendPlay(osc.oscP5, osc.oscDestination);
        if (i < movieRepository.length) {
           m = movieRepository[i][isOverlay]; 
           vidNum = i;
        } else {
           m = movieRepository[0][isOverlay];
           println("Movie index out of range");
        }
      }
      if (!playing) return;
      /*if (m == null) {
        playing = false;
        oscSendPlay(osc.oscP5, osc.oscDestination);
        return;
      }*/
      // Processing Movie library:
      //if (m.available()) m.read();
      image(m, 0, 0, width, height);
      if ( m.time() >= m.duration() ) {
        stop();
        oscSendPlay(osc.oscP5, osc.oscDestination);
      }
    }
    
    void oscSendPlay(OscP5 osc, NetAddress oscDestination) {
      OscMessage toggleOsc = new OscMessage("/Titles/Play");
      float a = 0.0;
      if (playing) a = 1.0;
      toggleOsc.add(a);
      osc.send(toggleOsc, oscDestination); 
    }

    void oscSendOverlay(OscP5 osc, NetAddress oscDestination) {
      OscMessage toggleOsc = new OscMessage("/Titles/Overlay");
      float a = 0.0;
      if (isOverlay == 1) a = 1.0;
      toggleOsc.add(a);
      osc.send(toggleOsc, oscDestination); 
    }
    
    void oscSendTitle(OscP5 osc, NetAddress oscDestination) {
      OscMessage toggleOsc = new OscMessage("/Titles/Select");
      float[] xs = new float[movieRepository.length];
      for (int i = 0; i < movieRepository.length; i++) {
          xs[i] = 0.0;
          if (i == vidNum) {
            xs[i] = 1.0;
          }
      }
      toggleOsc.add(xs);
      osc.send(toggleOsc, oscDestination); 
    }
    
   void oscSendState(OscP5 osc, NetAddress oscDestination) {
    oscSendTitle(osc,oscDestination);
    oscSendPlay(osc,oscDestination);
    oscSendOverlay(osc,oscDestination);
  }
    
    void stop() {
      playing = false;
      if (m != null) {
        m.stop();
      }
    }    

    void play() {
      if (m != null) {
        playing = true;
        m.jump(0.0);
        m.play();
      } else {
        oscSendPlay(osc.oscP5, osc.oscDestination);
      }
    }

}


class ImageBackgroundArtist extends BackgroundArtist {
  PImage[] images;
  int currentImage;
  
  ImageBackgroundArtist() {
    init();
  }

  void init() {
    // currentImage = images[0];
  }
  
  void paint() {
    // image(currentImage, 0, 0);
  }
}

class CamBackgroundArtist extends BackgroundArtist {
  Capture cam;
  String device;
  boolean active = false;
  
  CamBackgroundArtist(Object parent, String deviceName) {
    device = deviceName;
    cam = new Capture((PApplet) parent, 320, 240, device);
  }

  void init() {
  }
  
  void paint() {
    if (!active) return;
    if (cam.available() == true) {
       cam.read();
    }
    image(cam, 0, 0, width, height);
  }
}

// Normally the below would go in a separate Factory class, but Processing makes
// everythin an inner class, which prevents us having static methods.
String[] backgroundArtistTypes = {
    "BlankBackgroundArtist",
    "ImageBackgroundArtist",
    "MovieBackgroundArtist"
};


BackgroundArtist createBackgroundArtist(String t) {
    if (t.equals("BlankBackgroundArtist")) {
	    return new BackgroundArtist();
      //case ImageBgArtist:
      //      return new ImageBgArtist();
    } else if (t.equals("MovieBackgroundArtist")) {
      return new MovieBackgroundArtist(this);
    } else if (t.equals("ImageBackgroundArtist")) {
      return new ImageBackgroundArtist();
    } else {
	    println("Unknown or unimplemented artist type");
	    return null;
    }
   
}

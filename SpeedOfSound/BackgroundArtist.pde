class BackgroundArtist {
    color c;
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

    void paint() {
	// draws background
	background(c);
    }
}


class MovieBackgroundArtist extends BackgroundArtist {
    PImage[] frames;
    int currentFrame;
    int maxFrames = 25; // 25 fps * 5 seconds
    int totalFrames; // less than max if not enough in movie.
    int pvw, pvh;
    JMCMovieGL m;
    int beatTimer = 0;
    // Movie m;

    MovieBackgroundArtist() {
	    currentFrame = 0;
	    totalFrames = 0;
	    frames = new PImage[maxFrames];
    }

    void init(Object o) {
      m = (JMCMovieGL) o;
      // m = (Movie) o;
	    int counter = 0;
    }

    void paint() {
      if (beat.isKick()) {
        sosMovie.setCurrentTime(sosMovie.getCurrentTime() - 0.5);
      }
      
      PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
      
      pgl.beginGL();  
      {
        m.image(gl, 0, 0, width, height);
      }
      pgl.endGL();
        
        // if (m.available()) m.read();
        // image(m, 0, 0, width, height);
    }

}

class ImageBackgroundArtist extends BackgroundArtist {
  PImage[] images;
  int currentImage;
  
  void ImageBackgroundArtist() {
    init();
  }

  void init() {
    // currentImage = images[0];
  }
  
  void paint() {
    // image(currentImage, 0, 0);
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
      return new MovieBackgroundArtist();
    } else if (t.equals("ImageBackgroundArtist")) {
      return new ImageBackgroundArtist();
    } else {
	    println("Unknown or unimplemented artist type");
	    return null;
    }
   
}

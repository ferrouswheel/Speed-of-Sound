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
      m.speed(s);
      
    }

    void init(Object o) {
      // Object o is a array of movie filenames

      String movieFiles[] = (String[]) o;
      
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
      if (beat.isKick()) {
        // JMC
        //m.setCurrentTime(sosMovie.getCurrentTime() - 0.5);
        m.jump(m.duration() - 0.5);
      }
      
      // JMC:
      // m.image(gl, 0, 0, width, height);
      
      // Processing Movie library:
      //if (m.available()) m.read();
      image(m, 0, 0, width, height);
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
      return new MovieBackgroundArtist(this);
    } else if (t.equals("ImageBackgroundArtist")) {
      return new ImageBackgroundArtist();
    } else {
	    println("Unknown or unimplemented artist type");
	    return null;
    }
   
}

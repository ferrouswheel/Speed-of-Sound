
import jmcvideo.*;

class MovieBackgroundArtist extends BackgroundArtist {
    int beatTimer = 0;
    float beatJump = 0.0;
    float speed = 1.0;
    int vidNum = 0;
    String[] filenames;
    int totalMovies=0;

    void setCurrentSource(int i) {};
    
    void setSpeed(float s) {};

    String[] getMovieFilenames(String prefix) {
	File dir = new File(dataPath(""));
	Vector[] filenames;
	String[] children = dir.list();
	if (children == null) {
	    return new String[0];
	    // Either dir does not exist or is not a directory
	} else {
	    for (int i=0; i<children.length; i++) {
		// Get filename of file or directory
		String filename = children[i];
		if (!filename.startsWith(prefix)) {
		    children[i] = null;
		}
	    }
	} 
	return children;
    }

    int getNumberOfSources() {
	return totalMovies;
    }


}

class QTMovieBackgroundArtist extends MovieBackgroundArtist {
    int pvw, pvh;
    Movie m;
    // Preload all movie objects for fast switching hopefully
    Movie movieRepository[];
    // Index of current move
    PApplet parent;

    QTMovieBackgroundArtist(PApplet _parent) {
      parent = _parent;
    }
    
    void setSpeed(float s) {
      speed = s;
      m.speed(s);
      
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

    void init(Object o) {
      String movieFiles[] = getMovieFilenames((String) o);
      println("Loading background movies...");
      // load all movies 
      int count = 0;
      for (int i = 0; i < movieFiles.length ; i++) {
	  if (movieFiles[i] != null) count++;
      }
      movieRepository = new Movie[count];
      filenames = new String[count];
      totalMovies = count;
      count = 0;
      for (int i = 0; i < movieFiles.length; i++) {
	  if (movieFiles[i] != null) {
	     println("Loading " + movieFiles[i]);
	     movieRepository[count] = new Movie(parent,movieFiles[i]);
	     filenames[count] = movieFiles[i];
	     count++;
	  }
      }
      if (count == 0) println("No movies!");
      m = movieRepository[0];
      m.loop();
      println("Loaded background movies...");
    }

    void paint() {
      if (beatJump != 0.0 && beat.isKick()) {
        m.jump(m.time() + beatJump);
      }
      image(m, 0, 0, width, height);
      if (m.time() == 0 && speed < 0.0) m.jump(m.duration());
    }

}

class JMCMovieBackgroundArtist extends MovieBackgroundArtist {
    int pvw, pvh;
    JMCMovieGL m;
    // Preload all movie objects for fast switching hopefully
    JMCMovieGL movieRepository[];
    // Index of current move
    PApplet parent;

    JMCMovieBackgroundArtist(PApplet _parent) {
      parent = _parent;
    }
    
    void setCurrentSource(int i) {
      m.stop();
      if (i < movieRepository.length) {
         m = (JMCMovieGL)movieRepository[i];        
      } else {
         m = (JMCMovieGL)movieRepository[0];
         println("Movie index out of range");
      }
      m.loop();
    }
    
    void setSpeed(float s) {
      speed = s;
      m.setRate(s);
      
    }

    void init(Object o) {
      String movieFiles[] = getMovieFilenames((String) o);
      println("Loading background movies...");
      // load all movies 
      int count = 0;
      for (int i = 0; i < movieFiles.length ; i++) {
	  if (movieFiles[i] != null) count++;
      }
      movieRepository = new JMCMovieGL[count];
      filenames = new String[count];
      totalMovies = count;
      count = 0;
      for (int i = 0; i < movieFiles.length; i++) {
	  if (movieFiles[i] != null) {
	     println("Loading " + movieFiles[i]);
	     movieRepository[count] = new JMCMovieGL(parent,movieFiles[i], RGB);
	     filenames[count] = movieFiles[i];
	     count++;
	  }
      }
      if (count == 0) println("No movies!");
      m = movieRepository[0];
      m.loop();
      println("Loaded background movies...");
    }

    void paint() {
      if (beatJump != 0.0 && beat.isKick()) {
        m.setCurrentTime(m.getCurrentTime() + beatJump);
      }
      PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
      gl = pgl.beginGL();
      m.frameImage(gl);
      pgl.endGL();
      //image(m, 0, 0, width, height);
      if (m.getCurrentTime() == 0 && speed < 0.0) m.setCurrentTime(m.getDuration());
    }

}


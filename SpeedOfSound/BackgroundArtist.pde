class BackgroundArtist {

    BackgroundArtist() {
    }

    boolean doesClear() {
	// whether or not the background explicitly clears things first
	return true;
    }

    void paint() {
	// draws background
	background(0);
    }
}

// Normally the below would go in a separate Factory class, but Processing makes
// everythin an inner class, which prevents us having static methods.
String[] backgroundArtistTypes = {
    "BackgroundArtist",
    "ImageBgArtist",
    "MovieBgArtist"
};


BackgroundArtist createBackgroundArtist(String t) {
    if (t.equals("BackgroundArtist")) {
	return new BackgroundArtist();
    // uncomment these when they are implemented
    //case ImageBgArtist:
//      return new ImageBgArtist();
 //   case MovieBgArtist:
//      return new MovieBgArtist();
    } else {
	println("Unknown or unimplemented artist type");
	return null;
    }
   
}

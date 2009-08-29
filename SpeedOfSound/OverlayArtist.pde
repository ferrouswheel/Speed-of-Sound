class OverlayArtist {

    OverlayArtist() {
    }

    void paint(PImage i) {
    }
}

class OverlayArtist2 extends OverlayArtist {

    OverlayArtist2() {
    }

    void paint(PImage i) {
    }
}

// Normally the below would go in a separate Factory class, but Processing makes
// everythin an inner class, which prevents us having static methods.
String[] overlayArtistTypes = {
    "None"
};


OverlayArtist createOverlayArtist(String t) {
    if (t.equals("Asdasd")) {
        return new OverlayArtist2();
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

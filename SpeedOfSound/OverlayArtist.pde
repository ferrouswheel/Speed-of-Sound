class OverlayArtist {

    OverlayArtist() {
    }
    
    void init(Object o) {}

    void paint() {}
}

class BlurOverlayArtist extends OverlayArtist {
    // Used by old slow technique
    /*float v = 1.0/9.0;
    float[][] kernel = { { v, v, v },
                         { v, v, v },
                         { v, v, v } };*/
    // Now using accumulation buffer technique mentioned here:
    // http://processing.org/discourse/yabb2/YaBB.pl?num=1177605444
    float n;
    boolean active = false;
    

    BlurOverlayArtist() {
        init(new Double(0.90));
    }
    
    void init(Object o) {
        // LIGHT BLUR : n = 0.90
        // VERY STRONG BLUR : n = 0.99
        n = (float) ((Double)o).doubleValue();
       
        // These things are needed for initialising the OpenGL accumulation buffer.
        gl = (( PGraphicsOpenGL )g).gl;      
        gl.glClearAccum(0.0, 0.0, 0.0, 1.0);
        gl.glClear(GL.GL_ACCUM_BUFFER_BIT);
    }

    void paint() {
        if (active) {
          gl.glAccum( GL.GL_MULT, n );
          gl.glAccum( GL.GL_ACCUM, 1-n );
          gl.glAccum( GL.GL_RETURN, 1.0 );
        }
    }
}

class WaveformOverlayArtist extends OverlayArtist {
    AudioSource out;
    color c;
    boolean rotating = false;
    float angle;
    WaveformOverlayArtist() {
      c = 255;
      angle = 0.0;
      rotating = true;
    }
    
    void init(Object o) {
      out = (AudioSource) o;
    }

    void paint() {
      // draw the waveforms
      int hoffset = (height - 200) / 2;
      stroke(c);
      strokeWeight(4);
      int maxx = width;
      int extra=0;
      if (rotating) extra = (int) sqrt(width*width + height*height) - width;
      int centrex = width / 2;
      int centrey = height / 2;
      angle += .11/PI;
      if (angle > 2.0 * PI) angle = 0.0;
      pushMatrix();
      translate(centrex, centrey);
      rotate(angle);
      translate(-centrex, -centrey);
      for(int i = 0; i < out.bufferSize() - 1; i++)
      {
        float x1 = map(i, 0, out.bufferSize(), -extra/2, width+(extra/2));
        float x2 = map(i+1, 0, out.bufferSize(), -extra/2, width+(extra/2));
        line(x1, hoffset + 50 + out.left.get(i)*50, x2, hoffset + 50 + out.left.get(i+1)*50);
        line(x1, hoffset + 150 + out.right.get(i)*50, x2, hoffset + 150 + out.right.get(i+1)*50);
      }
      popMatrix();
    
    }  
  
}

// Normally the below would go in a separate Factory class, but Processing makes
// everythin an inner class, which prevents us having static methods.
String[] overlayArtistTypes = {
    "None",
    "BlurOverlayArtist",
    "WaveformOverlayArtist"
};


OverlayArtist createOverlayArtist(String t) {
    if (t.equals("BlurOverlayArtist")) {
        return new BlurOverlayArtist();
	// uncomment these when they are implemented
	//case ImageBgArtist:
    //      return new ImageBgArtist();
     //   case MovieBgArtist:
    //      return new MovieBgArtist();
    } else if (t.equals("WaveformOverlayArtist")) {
        return new WaveformOverlayArtist();
	    
    } else {
        println("Unknown or unimplemented artist type");
        return null;
    }
}

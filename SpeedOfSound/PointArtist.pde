class PointArtist {

    int beatSize = 40;
    int minSize = 0;
    float fadeProportion = 0.95;
    boolean active = true;
    boolean overlay = true;
        
    PointArtist() {
    }

    void paint(LemurPoint[] points) {
        if (!active) return;
        fill(0);
        rect(0, 0, width, height);
        fill(255);
        noStroke();
        for (int i = 0; i < 10; i++) {
            drawPointOutline(points[i]);
        }
        for (int i = 0; i < 10; i++) {
            drawPoint(points[i]);
        }
    }

    void drawPoint (LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        int lpSize = lp.currentSize;
        if (lp.detected()) {
            lpSize = beatSize;
        }
        
        if (lp.partialAlpha == false) {
          fill(255);
          ellipse(lp.x, lp.y, lpSize, lpSize);
        }

    }
    
    void drawPointOutline (LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        int lpSize = lp.currentSize;
        if (lp.detected()) {
            lpSize = beatSize;
        }
        
        if (lp.partialAlpha == true) {
           gl.glBlendFunc(GL.GL_ONE, GL.GL_ONE);
        }

        fill(64);
        ellipse(lp.x, lp.y, (lpSize + 3), (lpSize + 3));
        fill(128);
        ellipse(lp.x, lp.y, (lpSize + 2), (lpSize + 2));
        if (lp.partialAlpha == false) {
          fill(192);
          ellipse(lp.x, lp.y, (lpSize + 1), (lpSize + 1));
        }
        
        lp.currentSize = (int) constrain(lpSize * fadeProportion, minSize, beatSize);
    }

  void handleOSC(OscMessage o) {
    String path = o.addrPattern();
    String elements[] = path.split("/");
    if (elements[2].equals("SizeRange")) {
      int bottom = int(round(o.get(0).floatValue()));
      int top = int(round(o.get(1).floatValue()));
      beatSize = top * 10;
      minSize = bottom * 10;
    } else if (elements[2].equals("Active")) {
      float bool = o.get(0).floatValue();
      if (bool == 1.0) {
        active = true;
        //rorschachLayer.active = false;
      } else {
        active = false;
        //rorschachLayer.active = true;
      }
    } else if (elements[2].equals("Overlay")) {
      if (elements[3].equals("On")) {
        float bool = o.get(0).floatValue();
        if (bool == 1.0) {
          overlay = true;
          //rorschachLayer.active = false;
        } else {
          overlay = false;
          //rorschachLayer.active = true;
        }
      }
      // TODO: add overlay amount
    }
  }

  void oscSendState(OscP5 osc, NetAddress oscDestination) {
    oscSendRange(osc,oscDestination);
    oscSendActive(osc,oscDestination);
    oscSendOverlay(osc,oscDestination);
  }
  
  void oscSendRange(OscP5 osc, NetAddress oscDestination) {
    OscMessage toggleOsc = new OscMessage("/PointArtist/SizeRange");
    float[] vec = new float[2];
    vec[0] = minSize / 10;
    vec[1] = beatSize / 10;
    toggleOsc.add(vec);
    osc.send(toggleOsc, oscDestination);      
  }

  void oscSendActive(OscP5 osc, NetAddress oscDestination) {
    OscMessage toggleOsc = new OscMessage("/PointArtist/Active");
    float a = 0.0;
    if (active) a = 1.0;
    toggleOsc.add(a);
    osc.send(toggleOsc, oscDestination); 
  }

  void oscSendOverlay(OscP5 osc, NetAddress oscDestination) {
    OscMessage toggleOsc = new OscMessage("/PointArtist/Active");
    float a = 0.0;
    if (overlay) a = 1.0;
    toggleOsc.add(a);
    osc.send(toggleOsc, oscDestination); 
  }
        
}

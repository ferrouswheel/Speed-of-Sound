class PointArtist {

    int beatSize = 40;
    int minSize = 0;
    float fadeProportion = 0.95;
    boolean active = false;
    boolean overlay = true;
    
    boolean imageOn = true;
    float rotation = 0.0;
    float rotationV = 0.0;
    boolean rotateOn = true;
    // TODO, allow different images for each point
    PImage pointImage;
    PImage[] pointImages = new PImage[2];
    int currentImage = 0;
        
    PointArtist() {
      pointImages[0] = loadImage("yinYang.gif");
      pointImages[1] = loadImage("speaker.gif");
    }

    void paint(LemurPoint[] points) {
        if (!active) return;
        if (overlay) {
          fill(0);
          rect(0, 0, width, height);
        }
        fill(255);
        noStroke();
        if (!imageOn) {
          for (int i = 0; i < 10; i++) {
              drawPointOutline(points[i]);
          }
          for (int i = 0; i < 10; i++) {
              drawPoint(points[i]);
          }
        } else {
          for (int i = 0; i < 10; i++) {
              drawPointImage(points[i]);
          }
        }
          
    }
    
    void drawPointImage(LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        int lpSize = lp.currentSize;
        if (lp.detected()) {
            lpSize = beatSize;
            rotationV = 0.01;
        }
        if (rotateOn) {
          rotation += rotationV;
          rotationV -= 0.0001;
          if (rotationV < 0.0) rotationV = 0.0;
        } else {
          rotation = 0.0;
        }
        pushMatrix();
        translate((float)lp.x, (float)lp.y );
        rotate(rotation);
        image(pointImages[currentImage], -(lpSize / 2.0), - (lpSize / 2.0), (float)lpSize, (float)lpSize);
        popMatrix();
        lp.currentSize = (int) constrain(lpSize * fadeProportion, minSize, beatSize);
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
        float bool = o.get(0).floatValue();
        if (bool == 1.0) {
          overlay = true;
          //rorschachLayer.active = false;
        } else {
          overlay = false;
          //rorschachLayer.active = true;
        }
        oscSendOverlay(osc.oscP5, osc.oscDestination);
      }
      // TODO: add overlay amount
      else if (elements[2].equals("Image")) {
        if (elements[3].equals("On")) {
          float bool = o.get(0).floatValue();
          if (bool == 1.0) {
            imageOn = true;
          } else {
            imageOn = false;
          }
        } else if (elements[3].equals("Select")) {
          int imageCount = o.typetag().length();
            int bIndex = 0;
            for (int i = 0; i < imageCount; i++) {
              float x = o.get(i).floatValue();
              if (x == 1.0) {
                bIndex = i; break;
              }
            }
            println("Image selected : " + bIndex);
            currentImage = bIndex;
        }
      }
      else if (elements[2].equals("Rotate")) {
        float bool = o.get(0).floatValue();
        if (bool == 1.0) {
          rotateOn = true;
        } else {
          rotateOn = false;
        }
      }
  }

  void oscSendState(OscP5 osc, NetAddress oscDestination) {
    oscSendRange(osc,oscDestination);
    oscSendActive(osc,oscDestination);
    oscSendOverlay(osc,oscDestination);
    oscSendRotate(osc,oscDestination);
    oscSendImageOn(osc,oscDestination);
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
    OscMessage toggleOsc = new OscMessage("/PointArtist/Overlay");
    float a = 0.0;
    if (overlay) a = 1.0;
    toggleOsc.add(a);
    osc.send(toggleOsc, oscDestination); 
  }
  
  void oscSendImageOn(OscP5 osc, NetAddress oscDestination) {
    OscMessage toggleOsc = new OscMessage("/PointArtist/Image/On");
    float a = 0.0;
    if (imageOn) a = 1.0;
    toggleOsc.add(a);
    osc.send(toggleOsc, oscDestination); 
  }
  
  void oscSendImageSelect(OscP5 osc, NetAddress oscDestination) {
      OscMessage toggleOsc = new OscMessage("/PointArtist/Image/Select");
      float[] xs = new float[pointImages.length];
      for (int i = 0; i < pointImages.length; i++) {
          xs[i] = 0.0;
          if (i == currentImage) {
            xs[i] = 1.0;
          }
      }
      toggleOsc.add(xs);
      osc.send(toggleOsc, oscDestination); 
  }
  
  void oscSendRotate(OscP5 osc, NetAddress oscDestination) {
    OscMessage toggleOsc = new OscMessage("/PointArtist/Rotate");
    float a = 0.0;
    if (rotateOn) a = 1.0;
    toggleOsc.add(a);
    osc.send(toggleOsc, oscDestination); 
  }
        
}

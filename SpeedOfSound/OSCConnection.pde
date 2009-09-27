import oscP5.*;
import netP5.*;


class OSCConnection {
    public OscP5 oscP5;
    /* a NetAddress contains the ip address and port number of a remote location in the network. */
    public NetAddress oscDestination; 
    LemurPoint[] points;
    Object parent;

    OSCConnection (Object theParent, String server, int port) {
        /* create a new instance of oscP5. 
        * 12000 is the port number you are listening for incoming osc messages.
        */
        oscP5 = new OscP5(theParent,12000);
        
        parent = theParent;

        /* create a new NetAddress. a NetAddress is used when sending osc messages
        * with the oscP5.send method.
        */

        /* the address of the osc broadcast server */
        oscDestination = new NetAddress(server,port);
    }

    void setAll() {
      // Fired on app init. Sets the Lemur controls to init start values
      // TODO: move each of these to their respective class and call a sendToLemur() command
      // within each that passes the OSCConnection object.
      sendPointsToOSC(pointSets[currentPreset]);
      sendNumPointsToOSC();
      resetRorschachOSC();
      sendRorschachBeatIncrement();
      sendRorschachToggle();
      sendRorschachRadius();
      sendRorschachMode();
      sendMovementMode();
      sendPointArtistRange();
      sendMoveJumpDistance();
      sendGravityProportion();
    }

    void sendPointsToOSC(LemurPoint[] points) {
        /* Update lemur with the new points.. important for visualisation that
         * move the points around (but lemur physics should be turned off)
         */

        // Base path
        String pointPath = new String("/points/");// + p.index + "/");
        // send x,y coordinates
        OscMessage xOscMessage = new OscMessage(pointPath + "x");
        OscMessage yOscMessage = new OscMessage(pointPath + "y");
        float[] xs = new float[points.length];
        float[] ys = new float[points.length];
        //for (LemurPoint p : points) {
        for (int i = 0; i < points.length; i++) {
            LemurPoint p = points[i];
            xs[i] = constrain((float) p.x / width, 0.0, 1.0);
            ys[i] = constrain(1.0 - (float) p.y / height, 0.0, 1.0);
        }
        /* add a value to the OscMessage */
        xOscMessage.add(xs);
        yOscMessage.add(ys);
        /* send the OscMessage to a remote location */
        //xOscMessage.print();
        //print(Arrays.toString(xs));
        //yOscMessage.print();
        //print(Arrays.toString(ys));
        oscP5.send(xOscMessage, oscDestination);
        oscP5.send(yOscMessage, oscDestination);
    }

    void connectToPoints(LemurPoint[] points) {
        this.points = points;
        pMotion.notifyPointsUpdated(points);
        osc.sendPointsToOSC(points);  
    }

    void updateX(int i, float x) {
        if (points != null && i < points.length) {
            points[i].x = (int) (x * width);
        }
        pMotion.notifyPointsUpdated(points);
    }

    void updateY(int i, float y) {
        if (points != null && i < points.length) {
            points[i].y = (int) ( (1.0 - y) * height);
        }
        pMotion.notifyPointsUpdated(points);
    }
    
    void changePreset(int p) {
      if (p >= 0 && p < numPointSets) {
        currentPreset = p;
        connectToPoints(pointSets[currentPreset]);
      }
      sendNumPointsToOSC();
    }
    
    void sendNumPointsToOSC() {
      int active = 0;
      for (int i = 0; i < pointSets[currentPreset].length; i++) {
        if (pointSets[currentPreset][i].active) {
          active ++;
        }
      }
      
      OscMessage numOscMessage = new OscMessage("/NumPoints/x");
      float num = active;
      numOscMessage.add(num);
      
      oscP5.send(numOscMessage, oscDestination);
    }
    
    void resetRorschachOSC() { // Set all the Lemur controls to current values.      
      OscMessage ballsOsc = new OscMessage("/NumRorschachBalls/" + "x");
      float num = rorschachLayer.nBalls;
      ballsOsc.add(num);
      
      oscP5.send(ballsOsc, oscDestination);      
    }
    
    void sendRorschachToggle() { // Set all the Lemur controls to current values.      
      OscMessage toggleOsc = new OscMessage("/RorschachToggle/x");
      if (useRorschach) {
        toggleOsc.add(1.0);
      } else {
        toggleOsc.add(0.0);
      }
      oscP5.send(toggleOsc, oscDestination);      
    }
    
    void sendRorschachRadius() {
      OscMessage radiusOsc = new OscMessage("/BlobSize/x");
      float rad = rorschachLayer.radius;
      radiusOsc.add(rad);
      oscP5.send(radiusOsc, oscDestination);
      while(true) {
        if (!rorschachLayer.generatingImage) {
          rorschachLayer.generateImage();
          break;
        }
      }
    }
    
    void sendRorschachBeatIncrement() {
      OscMessage msg = new OscMessage("/BeatIncrement/x");
      msg.add(float(rorschachLayer.speedUp));
      oscP5.send(msg, oscDestination);
    }
    
    void sendRorschachMode() {
      OscMessage radiusOsc = new OscMessage("/BlobMoveMode/x");
      float[] vec = new float[8];
      for (int i = 0; i < 8; i++) {
        if (i == rorschachLayer.movementMode) {
          vec[i] = 1.0;
        } else {
          vec[i] = 0.0;
        }
      }
      radiusOsc.add(vec);
      oscP5.send(radiusOsc, oscDestination);
    }
    
    void sendMovementMode() {
      OscMessage radiusOsc = new OscMessage("/MovementMode/x");
      float[] vec = new float[10];
      for (int i = 0; i < 10; i++) {
        if (i == pMotion.mode) {
          vec[i] = 1.0;
        } else {
          vec[i] = 0.0;
        }
      }
      radiusOsc.add(vec);
      oscP5.send(radiusOsc, oscDestination);
    }
    
    void sendPointArtistRange() {
      OscMessage toggleOsc = new OscMessage("/SizeRange/x");
      float[] vec = new float[2];
      vec[0] = pArtist.minSize / 10;
      vec[1] = pArtist.beatSize / 10;
      toggleOsc.add(vec);
      oscP5.send(toggleOsc, oscDestination);      
    }
    
    void sendMoveJumpDistance() {      
      OscMessage jumpOsc = new OscMessage("/PointMotion/JumpDistance/x");
      jumpOsc.add(float(pMotion.jumpDistance));
      oscP5.send(jumpOsc, oscDestination);
    }

    void sendGravityProportion() {      
      OscMessage gOsc = new OscMessage("/PointMotion/GravityAmount/x");
      gOsc.add(pMotion.gProportion);
      oscP5.send(gOsc, oscDestination);
    }

    void handleMessage(OscMessage theOscMessage) {
        String path = theOscMessage.addrPattern();
        /* get and print the address pattern and the typetag of the received OscMessage */
        // println("SOS received an osc message with addrpattern "+path+" and typetag "+theOscMessage.typetag());
        //theOscMessage.print();
        String elements[] = path.split("/");
        // println(elements);
        if (elements[1].equals("points")) {
            //int pIndex = Integer.parseInt(path.substring(6,path.indexOf("/",6)));
            if (elements[2].equals("x")) {
                int pointCount = theOscMessage.typetag().length();
                for (int i = 0; i < pointCount; i++) {
                    float x = theOscMessage.get(i).floatValue();
                    updateX(i,x);
                }
            } else if (elements[2].equals("y")) {
                int pointCount = theOscMessage.typetag().length();
                for (int i = 0; i < pointCount; i++) {
                    float y = theOscMessage.get(i).floatValue();
                    updateY(i,y);
                }
            }
        } else if (elements[1].equals("PointsPreset") &&
            elements[2].equals("x")) {
            int presetCount = theOscMessage.typetag().length();
            int pIndex = 0;
            for (int i = 0; i < presetCount; i++) {
                float x = theOscMessage.get(i).floatValue();
                if (x == 1.0) {
                  pIndex = i; break;
                }
            }
            changePreset(pIndex);
        } else if (elements[1].equals("NumPoints")) {
          int numPoints = int(round(theOscMessage.get(0).floatValue()));
          println("NUM POINTS =======" + numPoints);
          for (int i = 0; i < pointSets[currentPreset].length; i++) {
            if (i >= numPoints) {
              pointSets[currentPreset][i].active = false;
            } else {
              pointSets[currentPreset][i].active = true;
            }
          }
        } else if (elements[1].equals("BackgroundSource")) {
          int backgroundCount = theOscMessage.typetag().length();
          int bIndex = 0;
          for (int i = 0; i < backgroundCount; i++) {
            float x = theOscMessage.get(i).floatValue();
            if (x == 1.0) {
              bIndex = i; break;
            }
          }
          bgArtist.setCurrentSource(bIndex);
        } else if (elements[1].equals("VideoSpeed")) {
          int speed = int(round(theOscMessage.get(0).floatValue()));
          if (speed == 1) {
            //sosMovie.setRate(speed);
            bgArtist.setSpeed(speed);
          } else {
            //sosMovie.setRate(speed * 2);
            bgArtist.setSpeed(speed * 2);
          }
        } else if (elements[1].equals("RorschachToggle")) {
          int bool = int(round(theOscMessage.get(0).floatValue()));
          if (bool == 1) {
            useRorschach = true;
          } else {
            useRorschach = false;
          }
          sendRorschachToggle();
        } else if (elements[1].equals("ResetRorschach")) {
          rorschachLayer.resetParams();
          while(true) {
            if (!rorschachLayer.generatingImage) {
              rorschachLayer.generateImage();
              break;
            }
          }
          setAll();
        } else if (elements[1].equals("SizeRange")) {
          int bottom = int(round(theOscMessage.get(0).floatValue()));
          int top = int(round(theOscMessage.get(1).floatValue()));
          pArtist.beatSize = top * 10;
          pArtist.minSize = bottom * 10;
        } else if (elements[1].equals("NumRorschachBalls")) {
          rorschachLayer.nBalls =  int(round(theOscMessage.get(0).floatValue()));;
        } else if (elements[1].equals("BlobMoveMode")) {
          int modeCount = theOscMessage.typetag().length();
          int mIndex = 0;
          for (int i = 0; i < modeCount; i++) {
            float x = theOscMessage.get(i).floatValue();
            if (x == 1.0) {
              mIndex = i; break;
            }
          }
          rorschachLayer.movementMode = mIndex;
        } else if (elements[1].equals("BlobSize")) {
          while(true) {
            if (!rorschachLayer.generatingImage) {
              rorschachLayer.radius = int(round(theOscMessage.get(0).floatValue()));
              rorschachLayer.generateImage();
              break;
            }
          }
        } else if (elements[1].equals("MovementMode")) {          
          int motionCount = theOscMessage.typetag().length();
          int mIndex = 0;
          for (int i = 0; i < motionCount; i++) {
            float x = theOscMessage.get(i).floatValue();
            if (x == 1.0) {
              mIndex = i; break;
            }
          }
          pMotion.setMode(mIndex);
        } else if (elements[1].equals("PointMotion")) {
          if (elements[2].equals("JumpDistance")) {
            pMotion.jumpDistance = int(round(theOscMessage.get(0).floatValue()));
          } else if (elements[2].equals("GravityAmount")) {
            pMotion.gProportion = theOscMessage.get(0).floatValue();
          }
        } else if (elements[1].equals("BeatIncrement")) {
          rorschachLayer.speedUp = int(round(theOscMessage.get(0).floatValue()));
          println(rorschachLayer.speedUp + "  WHEEEEEEE");
        }
    }

}

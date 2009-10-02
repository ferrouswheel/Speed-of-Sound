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
        if (debug) println("created new OSCConnection");
    }

    void setAll() {
      // Fired on app init. Sets the Lemur controls to init start values
      // TODO: move each of these to their respective class and call a sendToLemur() command
      // within each that passes the OSCConnection object.
      sendPointsToOSC(pointSets[currentPreset]);
      sendNumPointsToOSC();
      sendCameraOn();
      sendBGMovieOn();

      pArtist.oscSendState(oscP5, oscDestination);
      pMotion.oscSendState(oscP5, oscDestination);
      rorschachLayer.oscSendState(oscP5, oscDestination);
      titleArtist.oscSendState(oscP5, oscDestination);
      if (debug) println("Sent state to OSC");
    }

    void sendPointsToOSC(LemurPoint[] points) {
        /* Update lemur with the new points.. important for visualisation that
         * move the points around (but lemur physics should be turned off)
         */

        // Base path
        String pointPath = new String("/Points/");// + p.index + "/");
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
        sendNumPointsToOSC();
      }
    }
    
    void sendNumPointsToOSC() {
      int active = 0;
      for (int i = 0; i < pointSets[currentPreset].length; i++) {
        if (pointSets[currentPreset][i].active) {
          active ++;
        }
      }
      
      OscMessage numOscMessage = new OscMessage("/Points/Num");
      float num = active;
      numOscMessage.add(num);
      
      oscP5.send(numOscMessage, oscDestination);
    }
    
    void sendCameraOn() {
      OscMessage cOsc = new OscMessage("/Camera/On/x");
      float[] vec = new float[cameras.length];
      for (int i = 0; i < cameras.length; i++) {
        if (cameras[i].active) {
          vec[i] = 1.0;
        }else {
          vec[i] = 0.0; 
        }
      }
      cOsc.add(vec);
      oscP5.send(cOsc, oscDestination);
    }

    void sendBGMovieOn() {
      OscMessage vidOsc = new OscMessage("/Background/Video/Select");
      float vid = 0.0;
      if (bgArtist.active) vid = 1.0;
      vidOsc.add(vid);
      oscP5.send(vidOsc, oscDestination);
    }

    void handleMessage(OscMessage theOscMessage) {
        String path = theOscMessage.addrPattern();
        /* get and print the address pattern and the typetag of the received OscMessage */
        // println("SOS received an osc message with addrpattern "+path+" and typetag "+theOscMessage.typetag());
        String elements[] = path.split("/");
        //println("Received OSC message...");
        //theOscMessage.print();
        
        if (elements[1].equals("Points")) {
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
            else if (elements[2].equals("Reset")) {
              createLemurPoints(false);
            } else if (elements[2].equals("Preset")) {
              int presetCount = theOscMessage.typetag().length();
              int pIndex = 0;
              for (int i = 0; i < presetCount; i++) {
                  float x = theOscMessage.get(i).floatValue();
                  if (x == 1.0) {
                    pIndex = i; break;
                  }
              }
              changePreset(pIndex);
            } 
            else if (elements[2].equals("Num")) {
              int numPoints = int(round(theOscMessage.get(0).floatValue()));
              println("NUM POINTS =======" + numPoints);
              for (int i = 0; i < pointSets[currentPreset].length; i++) {
                if (i >= numPoints) {
                  pointSets[currentPreset][i].active = false;
                } else {
                  pointSets[currentPreset][i].active = true;
                }
              }
            }
        } else if (elements[1].equals("PointArtist")) {
            pArtist.handleOSC(theOscMessage);
        } else if (elements[1].equals("Rorschach")) {
            rorschachLayer.handleOSC(theOscMessage);
        }
        else if (elements[1].equals("PointMotion")) {
          pMotion.handleOSC(theOscMessage);
        }
        else if (elements[1].equals("Overlay")) {
          if (elements[2].equals("On")) {
            if (theOscMessage.get(0).floatValue() == 1.0) {
              overlayOn = true;
              // Ensure at least one of points or rorschach are on:
              if (!rorschachLayer.active) pArtist.active = true;
            } else {
              overlayOn = false;
            }
          }
        }
        //// TITLES
        else if (elements[1].equals("Titles")) {
          if (elements[2].equals("Select")) {
            int backgroundCount = theOscMessage.typetag().length();
            int bIndex = 0;
            for (int i = 0; i < backgroundCount; i++) {
              float x = theOscMessage.get(i).floatValue();
              if (x == 1.0) {
                bIndex = i; break;
              }
            }
            titleArtist.setCurrentSource(bIndex);
          } else if (elements[2].equals("Play")) {
            float bool = theOscMessage.get(0).floatValue();
            if (bool == 1.0) {
              titleArtist.play();
            } else {
              titleArtist.stop();
            }
          } else if (elements[2].equals("Overlay")) {
            float bool = theOscMessage.get(0).floatValue();
            if (bool == 1.0) {
              titleArtist.isOverlay = 1;
              titleArtist.setCurrentSource(titleArtist.vidNum);
            } else {
              titleArtist.isOverlay = 0;
              titleArtist.setCurrentSource(titleArtist.vidNum);
            }
          }
        }
        /////// VIDEO 
        else if (elements[1].equals("BackgroundSource")) {
          int backgroundCount = theOscMessage.typetag().length();
          int bIndex = 0;
          for (int i = 0; i < backgroundCount; i++) {
            float x = theOscMessage.get(i).floatValue();
            if (x == 1.0) {
              bIndex = i; break;
            }
          }
          bgArtist.setCurrentSource(bIndex);
        }
        else if (elements[1].equals("VideoSpeed")) {
          int speed = int(round(theOscMessage.get(0).floatValue()));
          if (speed == 1) {
            //sosMovie.setRate(speed);
            bgArtist.setSpeed(speed);
          } else {
            //sosMovie.setRate(speed * 2);
            bgArtist.setSpeed(speed * 2);
          }
        } 
        else if (elements[1].equals("Camera")) {
          if (elements[2].equals("On")) {
            for (int i = 0; i < cameras.length; i++) {
              float x = theOscMessage.get(i).floatValue();
              if (x == 1.0) {
                cameras[i].active = true;
              } else {
                cameras[i].active = false;
              }
            }
            
          }
        }

    }
    

}

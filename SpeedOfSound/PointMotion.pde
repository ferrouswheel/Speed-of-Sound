class PointMotion {
    // TODO: The different motion modes should all be separate classes
    // inheriting from PointMotion!
  
    int jumpDistance;
    boolean isGoingLeft = false; // Switch this to bounce left and right
    int cumulativeIncrement = 0; // Track how far the ball has moved from init
    
    // For gravityMove
    boolean gravityOn = false;
    float[][] pointBuffer;
    float gProportion = 0.5;
    float gCurrentProportion = 1.0;
    
    int mode = 0; // Mode. 
    // 0 = off. 
    // 1 = Crawl around screen.
    // 2 = bounce left/right 
    
    PointMotion() {
      
      
    }

    void setMode(int m) {
       mode = m;
       LemurPoint[] points = pointSets[currentPreset];
       // Update point locations in the buffer
       for (int i = 0; i < points.length; i++) {
            pointBuffer[i][0] = points[i].x;
            pointBuffer[i][1] = points[i].y;
       }
    }
     
    // This should be called when something other than the PointMotion object
    // changes the point positions.
    void notifyPointsUpdated(LemurPoint[] points) {
       if (pointBuffer == null) {
        pointBuffer = new float[points.length][2];
       }
       isGoingLeft = false;
       cumulativeIncrement = 0;
       gravityOn = false;
       gCurrentProportion = 1.0;
       for (int i = 0; i < points.length; i++) {
            pointBuffer[i][0] = points[i].x;
            pointBuffer[i][1] = points[i].y;
       }
    }
       

    void move(LemurPoint[] points) {
      if (mode == 1) {
        for (int i = 0; i < points.length; i++) {
          crawlPoint(points[i]);
        }
      } else if (mode == 2) {
        for (int i = 0; i < points.length; i++) {
          bouncePoint(points[i]);
        }
      } else if (mode == 3) {
        swirlPoints(points);
      } else if (mode == 4) {
        
        gravityPoints(points);
      } else {
        // No movement if exceed bounds
      }
    }

    void crawlPoint(LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        if (lp.detected()) {
            if (lp.x < width - jumpDistance) {
                lp.x = lp.x + jumpDistance;
            } else {
                lp.x = jumpDistance;
            }
        }
    }

    void bouncePoint(LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        if (lp.detected()) {
          if (isGoingLeft == true ) { // Move Left
            lp.x = lp.x - jumpDistance;
            cumulativeIncrement = cumulativeIncrement - jumpDistance;
            if (cumulativeIncrement <= -100) {
              isGoingLeft = false;
            }
          } else { // Move right
            lp.x = lp.x + jumpDistance;
            cumulativeIncrement = cumulativeIncrement + jumpDistance;
            if (cumulativeIncrement >= 100) {
              isGoingLeft = true;
            }
          }
        }
    }

    void swirlPoints(LemurPoint[] points) {
      float rSquared = 0;
      float theta = 0;
      float maxdim = max(width,height);
      float vel0 = PI / 50.0; // In radians
      float vel = 0;
      float half_width = (float) width / 2.0;
      float half_height = (float) height / 2.0;
      for(int i = 0; i < points.length; i++){
        rSquared = (points[i].x - half_width) * (points[i].x - half_width) +
                   (points[i].y - half_height) * (points[i].y - half_height);
        theta = atan2(points[i].y - half_height, points[i].x - half_width);

// What does the if statement do?
/*        if(rSquared > (maxdim + radius) * (maxdim + radius) * .25){
            points[i].x = int(round(random(radius,width-radius)));
            points[i].y = int(round(random(radius,height-radius)));
           }*/
        vel = vel0 + (sqrt(rSquared) / width) / 100.0;
        theta += vel;
        points[i].x = (int) (sqrt(rSquared) * cos(theta) + half_width);
        points[i].y = (int) (sqrt(rSquared) * sin(theta) + half_height);
      }
    }
    
    void gravityPoints(LemurPoint[] points) {
      float r = 0;
      float theta = 0;
      float half_width = (float) width / 2.0;
      float half_height = (float) height / 2.0;
      LemurPoint lp;
      float r_delta = 0.0;
      float inc = 0.02;

      
      for(int i = 0; i < points.length; i++){
        lp = points[i];
        if (!lp.active) return; // do nothing is not being used
        if (lp.detected() && !gravityOn) {
            gravityOn = true;
        }
        if (gravityOn) {
            // If gProportion is negative...
            // (repulsion from center)
            if (gProportion < 0) {
              if (gCurrentProportion < 1.0 - gProportion) {
                 gCurrentProportion += inc;
              } else {
                 gravityOn = false;
              }
            } else {
              // If gProportion is positive
              // (attraction to center)
              if (gCurrentProportion > 1.0 - gProportion) {
                 gCurrentProportion -= inc;
              } else {
                 gravityOn = false;
              }
            }
        } else {
            if (gProportion < 0) {
               if (gCurrentProportion > 1.0) {
                 gCurrentProportion -= 0.05;
               } else {
                 gCurrentProportion = 1.0;
               }
            } else {
               if (gCurrentProportion < 1.0) {
                 gCurrentProportion += 0.05;
               } else {
                 gCurrentProportion = 1.0;
               }
            }
        }
        points[i].x = (int) ((pointBuffer[i][0] - half_width) * gCurrentProportion + half_width);
        points[i].y = (int) ((pointBuffer[i][1] - half_height) * gCurrentProportion + half_height);
             
      }
    }

}

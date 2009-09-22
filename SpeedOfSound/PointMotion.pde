class PointMotion {

    public int jumpDistance = 5;
    boolean isGoingLeft = false; // Switch this to bounce left and right
    int cumulativeIncrement = 0; // Track how far the ball has moved from init
    int mode = 0; // Mode. 
    // 0 = off. 
    // 1 = Crawl around screen.
    // 2 = bounce left/right 
    
    PointMotion() {}

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
      int radius = pArtist.minSize / 2;
      float rSquared = 0;
      float theta = 0;
      float vel0 = max(width,height)/150;
      float vel = vel0+0;
      for(int i = 0; i < points.length; i++){
        rSquared = (points[i].x-width/2)*(points[i].x-width/2)+
                   (points[i].y-height/2)*(points[i].y-height/2);
        theta = atan2(points[i].y-height/2,points[i].x-width/2);

        if(rSquared > max(width+radius,height+radius)*max(width+radius,height+radius)*.25){
            points[i].x = int(round(random(radius,width-radius)));
            points[i].y = int(round(random(radius,height-radius)));
           }
        vel = vel0*(1-rSquared/(width*width/(40)));
        points[i].x+= vel*cos(theta+PI/2);
        points[i].y+= vel*sin(theta+PI/2);
      }
    }
}

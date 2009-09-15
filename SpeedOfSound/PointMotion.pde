class PointMotion {

    public int jumpDistance = 5;
    boolean isGoingLeft = false; // Switch this to bounce left and right
    int cumulativeIncrement = 0; // Track how far the ball has moved from init
    public int mode = 0; // Mode. 
    // 0 = off. 
    // 1 = Crawl around screen.
    // 2 = bounce left/right 
    
    PointMotion() {}

    void move(LemurPoint[] points) {
      if (mode != 0) {
        for (int i = 0; i < points.length; i++) {
          if (mode == 1) {
            crawlPoint(points[i]);
          } else if (mode == 2) {
            bouncePoint(points[i]);
          }
        }
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
        println("foo");
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
}

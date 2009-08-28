class PointArtist {

    PointArtist() {
    }

    void update(LemurPoint[] points) {
        for (int i = 0; i < 10; i++) {
            drawPoint(points[i]);
        }
    }

    void drawPoint (LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        int lpSize = lp.currentSize;
        if (lp.detected()) {
           lpSize = 32;
          /*if (x < 635) {
           x = x + 5;
          } else {
           x = 10;
          }*/
        }
        ellipse(lp.x, lp.y, lpSize, lpSize);
        lp.currentSize = (int) constrain(lpSize * 0.95, 10, 32);
    }

}

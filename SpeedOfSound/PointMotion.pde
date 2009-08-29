class PointMotion {

    int jumpDistance = 5;

    PointMotion() {}

    void move(LemurPoint[] points) {
        for (int i = 0; i < points.length; i++) {
            movePoint(points[i]);
        }
    }

    void movePoint(LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        if (lp.detected()) {
            if (lp.x < width - jumpDistance) {
                lp.x = lp.x + jumpDistance;
            } else {
                lp.x = jumpDistance;
            }
        }
    }

}

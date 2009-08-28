class PointArtist {

    int jumpDistance = 5;
    int beatSize = 64;
    int minSize = 10;
    float fadeProportion = 0.95;

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
            lpSize = beatSize;

            if (lp.x < width - jumpDistance) {
                lp.x = lp.x + jumpDistance;
            } else {
                lp.x = jumpDistance;
            }
        }
        ellipse(lp.x, lp.y, lpSize, lpSize);
        lp.currentSize = (int) constrain(lpSize * fadeProportion, minSize, beatSize);
    }

}

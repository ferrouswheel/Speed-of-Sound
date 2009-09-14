class PointArtist {

    int beatSize = 200;
    int minSize = 60;
    float fadeProportion = 0.95;
    PointArtist() {
    }

    void paint(LemurPoint[] points) {
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
        
        fill(255);
        ellipse(lp.x, lp.y, lpSize, lpSize);

    }
    
    void drawPointOutline (LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        int lpSize = lp.currentSize;
        if (lp.detected()) {
            lpSize = beatSize;
        }

        fill(64);
        ellipse(lp.x, lp.y, (lpSize + 6), (lpSize + 6));
        fill(128);
        ellipse(lp.x, lp.y, (lpSize + 4), (lpSize + 4));
        fill(192);
        ellipse(lp.x, lp.y, (lpSize + 2), (lpSize + 2));
        
        lp.currentSize = (int) constrain(lpSize * fadeProportion, minSize, beatSize);
    }
}

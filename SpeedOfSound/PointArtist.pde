class PointArtist {

    int beatSize = 40;
    int minSize = 0;
    float fadeProportion = 0.95;
    boolean active = true;
        
    PointArtist() {
    }

    void paint(LemurPoint[] points) {
        if (!active) return;
        fill(0);
        rect(0, 0, width, height);
//        fill(255);
//        ellipse(5, 5, 10, 10);
        fill(255);
//        ellipse(width/2.0, height/2.0, 10, 10);
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
}

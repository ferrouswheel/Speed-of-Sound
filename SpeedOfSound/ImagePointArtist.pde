class ImagePointArtist extends PointArtist {

    int beatSize = 64;
    int minSize = 20;
    float rotation = 0.0;
    float rotationV = 0.0;
    boolean rotateOn = true;
    float fadeProportion = 0.95;
    // TODO, allow different images for each point
    PImage pointImage;

    ImagePointArtist(String imgFilename) {
        pointImage = loadImage(imgFilename);
    }

    void drawPoint (LemurPoint lp) {
        if (!lp.active) return; // do nothing is not being used
        int lpSize = lp.currentSize;
        if (lp.detected()) {
            lpSize = beatSize;
            rotationV = 0.01;
        }
        rotation += rotationV;
        rotationV -= 0.0001;
        if (rotationV < 0.0) rotationV = 0.0;
        pushMatrix();
        translate((float)lp.x, (float)lp.y );
        rotate(rotation);
        image(pointImage, -(lpSize / 2.0), - (lpSize / 2.0), (float)lpSize, (float)lpSize);
        popMatrix();
        lp.currentSize = (int) constrain(lpSize * fadeProportion, minSize, beatSize);
    }

}

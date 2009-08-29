class ImagePointArtist extends PointArtist {

    int beatSize = 64;
    int minSize = 10;
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
        }
        image(pointImage, (float)lp.x, (float)lp.y, (float)lpSize, (float)lpSize);
        lp.currentSize = (int) constrain(lpSize * fadeProportion, minSize, beatSize);
    }

}

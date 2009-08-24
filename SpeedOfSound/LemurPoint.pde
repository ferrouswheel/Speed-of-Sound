class LemurPoint
{
  BeatDetect beat = null;

  // Whether or not the point is being drawn or is affecting the scene
  public boolean active = true;
  
  // The range that 
  int lowerBandIndex = 1;
  int upperBandIndex = 10;
  // Threshold is the number of bands that need to have registered a beat.
  int threshold = 1;
  
  // Location of the point
  int x,y;
  int currentSize;
  
  LemurPoint(BeatDetect b, int start_x, int start_y) {
    // Take a passed BeatDetect object which is shared amongst LemurPoints
    beat = b;
    x = start_x;
    y = start_y;
    currentSize = 10;

  }
  
  void setBand(int low, int high, int t) {
    lowerBandIndex = low;
    upperBandIndex = high;
    threshold = t;
  }
  
  boolean detected() {
    return beat.isRange(lowerBandIndex,upperBandIndex,1);
  }
  
  void drawPoint() {
    if (!active) return; // do nothing is not being used
    int lpSize = currentSize;
    if (detected()) {
      lpSize = 32;
      if (x < 635) {
       x = x + 5;
      } else {
       x = 10;
      }
      
    }
    ellipse(x, y, lpSize, lpSize);
    currentSize = (int) constrain(lpSize * 0.95, 10, 32);
  }
  
}

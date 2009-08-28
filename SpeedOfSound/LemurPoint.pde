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
  public int x,y;
  int currentSize;
  public int index;
  
  LemurPoint(BeatDetect b, int start_x, int start_y, int i) {
    // Take a passed BeatDetect object which is shared amongst LemurPoints
    beat = b;
    x = start_x;
    y = start_y;
    currentSize = 10;
    index = i;
  }
  
  void setBand(int low, int high, int t) {
    lowerBandIndex = low;
    upperBandIndex = high;
    threshold = t;
  }
  
  boolean detected() {
    return beat.isRange(lowerBandIndex,upperBandIndex,1);
  }
  
  
}

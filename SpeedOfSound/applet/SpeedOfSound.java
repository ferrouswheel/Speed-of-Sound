import processing.core.*; 
import processing.xml.*; 

import ddf.minim.*; 
import ddf.minim.analysis.*; 

import java.applet.*; 
import java.awt.*; 
import java.awt.image.*; 
import java.awt.event.*; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class SpeedOfSound extends PApplet {

/**
 * Speed of Sound Lemur interface
 * by Joel Pitt, Kelly, Will Marshall
 *
 * Adapted from example:
 * Frequency Energy 
 * by Damien Di Fede.
 *  
 * This sketch demonstrates how to use the BeatDetect object in FREQ_ENERGY mode.
 * You can use <code>isKick</code>, <code>isSnare</code>, </code>isHat</code>, 
 * <code>isRange</code>, and <code>isOnset(int)</code> to track whatever kind 
 * of beats you are looking to track, they will report true or false based on 
 * the state of the analysis. To "tick" the analysis you must call <code>detect</code> 
 * with successive buffers of audio. You can do this inside of <code>draw</code>, 
 * but you are likely to miss some audio buffers if you do this. The sketch implements 
 * an <code>AudioListener</code> called <code>BeatListener</code> so that it can call 
 * <code>detect</code> on every buffer of audio processed by the system without repeating 
 * a buffer or missing one.
 * 
 * This sketch plays an entire song so it may be a little slow to load.
 */




Minim minim;
AudioPlayer song;
BeatDetect beat;
BeatListener bl;
Integer a;

LemurPoint[] points = new LemurPoint[10];

public void setup()
{
  size(512, 200);
  smooth();
  
  minim = new Minim(this);

  song = minim.loadFile("garbage_bin_fight.mp3", 2048);
  song.loop();
  System.out.println(song.sampleRate());

  // a beat detection object that is FREQ_ENERGY mode that 
  // expects buffers the length of song's buffer size
  // and samples captured at songs's sample rate
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  
  // make a new beat listener, so that we won't miss any buffers for the analysis
  bl = new BeatListener(beat, song);

  // set the sensitivity to 300 milliseconds
  // After a beat has been detected, the algorithm will wait for 300 milliseconds 
  // before allowing another beat to be reported. You can use this to dampen the 
  // algorithm if it is giving too many false-positives. The default value is 10, 
  // which is essentially no damping. If you try to set the sensitivity to a negative value, 
  // an error will be reported and it will be set to 10 instead. 
  beat.setSensitivity(2);

  textFont(createFont("SanSerif", 16));
  textAlign(CENTER);

  // Create LemurPoint objects
  for (int i = 0; i < 10; i++) {
    a = i + 1;
    points[i] = new LemurPoint(beat, a*40, a*15);
    points[i].setBand(i*2, i*2 + 3, 2);
  }    
}

public void draw()
{
  background(0);
  fill(255);

  for (int i = 0; i < 10; i++) {
    points[i].drawPoint();
  }
  beat.drawGraph(this);

}

public void stop()
{
  // always close Minim audio classes when you are finished with them
  song.close();
  // always stop Minim before exiting
  minim.stop();
  // this closes the sketch
  super.stop();
}
class BeatListener implements AudioListener
{
  private BeatDetect beat;
  private AudioPlayer source;
  
  BeatListener(BeatDetect beat, AudioPlayer source)
  {
    this.source = source;
    this.source.addListener(this);
    this.beat = beat;
  }
  
  public void samples(float[] samps)
  {
    beat.detect(source.mix);
  }
  
  public void samples(float[] sampsL, float[] sampsR)
  {
    beat.detect(source.mix);
  }
}
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
  
  public void setBand(int low, int high, int t) {
    lowerBandIndex = low;
    upperBandIndex = high;
    threshold = t;
  }
  
  public boolean detected() {
    return beat.isRange(lowerBandIndex,upperBandIndex,1);
  }
  
  public void drawPoint() {
    if (!active) return; // do nothing is not being used
    int lpSize = currentSize;
    if (detected()) {
      lpSize = 32;
      if (x < 505) {
       x = x + 5;
      } else {
       x = 10;
      }
      
    }
    ellipse(x, y, lpSize, lpSize);
    currentSize = (int) constrain(lpSize * 0.95f, 10, 32);
  }
  
}

  static public void main(String args[]) {
    PApplet.main(new String[] { "--bgcolor=#FFFFFF", "SpeedOfSound" });
  }
}

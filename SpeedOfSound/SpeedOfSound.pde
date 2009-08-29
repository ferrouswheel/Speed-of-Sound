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

import ddf.minim.*;
import ddf.minim.analysis.*;

import oscP5.*;

Minim minim;
AudioSource song;
BeatDetect beat;
BeatListener bl;
OSCConnection osc;

// These things draw the scene... all of them can be beat responsive...

// The BackgroundArtist is called first, it optionally clears the canvas and
// then sets the background... blank/movie frame/image/whatever.
BackgroundArtist bgArtist;

// PointMotion is used to set the point locations, after it updates, it will
// also update the lemur points via OSC (think the Simian mobile disco vid where
// the circles were moving in response to the beat).
PointMotion pMotion;

// PointArtist draws some kind of image based on where the points currently are
PointArtist pArtist;

// OverlayArtist takes the scene as it's currently drawn and then modifies it
// some how... examples could be motion blur, water ripples etc.
OverlayArtist oArtist;

Integer a;

LemurPoint[] points = new LemurPoint[10];

void setup()
{
  //size(640, 480);
  size(800, 600);
  // Fullscreen
  //size(screen.width, screen.height);
  frameRate(25);
  smooth();
  
  minim = new Minim(this);
  osc = new OSCConnection(this,"192.168.0.2",8000);

  song = minim.getLineIn(Minim.STEREO, 512);
  // song.play();

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

  bgArtist = createBackgroundArtist("BackgroundArtist");
  pArtist = new PointArtist(); // createPointArtist("CirclePointArtist");
  pMotion = new PointMotion(); //null; //PointMotionFactory.createMotion(NoMotion);
  oArtist = createOverlayArtist("None");

  // Create LemurPoint objects
  for (int i = 0; i < 10; i++) {
    a = i + 1;
    points[i] = new LemurPoint(beat, a*40, a*15, i);
    points[i].setBand(i*2, i*2 + 3, 2);
  }    
  osc.connectToPoints(points);
  
}

void draw()
{
    bgArtist.paint();
    fill(255);

    if (pMotion != null) {
	pMotion.move(points);
	/* comment out this line to turn off syncing the lemur points,
	 * (you could still manually sync the lemur points with "p")
	 */
	osc.sendPointsToOSC(points);  
    }
    if (pArtist != null) pArtist.paint(points);
    //beat.drawGraph(this);
    if (oArtist != null) oArtist.paint(get());

}

void stop()
{
  // always close Minim audio classes when you are finished with them
  song.close();
  // always stop Minim before exiting
  minim.stop();
  // this closes the sketch
  super.stop();
}

void keyPressed() {
  OscMessage m;
  switch(key) {
    case('c'):
      /* connect to the broadcaster */
      m = new OscMessage("/server/connect",new Object[0]);
      osc.oscP5.flush(m,osc.oscDestination);  
      break;
    case('d'):
      /* disconnect from the broadcaster */
      m = new OscMessage("/server/disconnect",new Object[0]);
      osc.oscP5.flush(m,osc.oscDestination);  
      break;
    case('p'):
      /* send points to OSC */
      osc.sendPointsToOSC(points);  
      break;

  }  
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
    osc.handleMessage(theOscMessage);
}

/**
 * Speed of Sound Lemur interface
 * by Joel Pitt, Kelly, Will Marshall
 *
 * Adapted from example:
 * Frequency Energy 
 * by Damien Di Fede.
 */

import jmcvideo.*;
import processing.video.*;
import processing.opengl.*;
import javax.media.opengl.*;
import javax.media.opengl.glu.*;
import codeanticode.glgraphics.*;

import ddf.minim.*;
import ddf.minim.analysis.*;

import oscP5.*;

GL gl;

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
OverlayArtist[] oArtists;

int numPointSets = 14;
int currentPreset = 0;
LemurPoint[][] pointSets = new LemurPoint[numPointSets][];

JMCMovieGL sosMovie;
// Movie sosMovie;

void setup()
{
  // We use OpenGL because it's the fastest, but it does break thinks that
  // try to interact with the drawing buffer via the the pixel array
  // (because swapping the data from the video card to memory is relatively
  // slow).
  
  size(640, 360, GLConstants.GLGRAPHICS);  
  
  // Fullscreen
  // size(screen.width, screen.height, GLConstants.GLGRAPHICS);
  
  // Processing seems to force 2x smooth if it's not explicitly disabled
  hint(DISABLE_OPENGL_2X_SMOOTH);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  smooth();
  gl = (( PGraphicsOpenGL )g).gl;
  gl.glEnable(GL.GL_LINE_SMOOTH);

  frameRate(60);
  smooth();

  minim = new Minim(this);
  osc = new OSCConnection(this,"192.168.0.2",8000);

  song = minim.getLineIn(Minim.STEREO, 512);
  // song.play(); // needed if the song is from an mp3 file

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
  beat.setSensitivity(400);

  textFont(createFont("SanSerif", 16));
  textAlign(CENTER);

  // TODO ensure all artists are created via the factory methods (e.g.
  // createBackgroundArtist() )

  // bgArtist = createBackgroundArtist("BlankBackgroundArtist");
  // color c = #550000;
  // bgArtist.init(new Integer(c));

  // Load a movie for the background movie artist
  // TODO: it's current set up to read 125 frames and animate them... except it
  // doesn't work, it just displays a single frame.
  // It's trivial to play a movie directly, but it's really slow using the
  // Quicktime based Processing video library.
  // sosMovie = new Movie(this, "carnival2.mov");
  sosMovie = movieFromDataPath("fox.mov"); // JMC
  sosMovie.loop();
  bgArtist = createBackgroundArtist("MovieBackgroundArtist");
  bgArtist.init(sosMovie);
//  sosMovie.stop();

  // pArtist = new ImagePointArtist("yinYang.gif"); // createPointArtist("CirclePointArtist");
  pArtist = new PointArtist();
  pMotion = null; //new PointMotion(); //null; //PointMotionFactory.createMotion(NoMotion);

  // WITH waveformoverlay
  oArtists = new OverlayArtist[2];
  oArtists[0] = createOverlayArtist("WaveformOverlayArtist");
  oArtists[0].init(song);
  oArtists[1] = createOverlayArtist("BlurOverlayArtist");
  oArtists[1].init(new Double(0.50));
  
  // WITHOUT
  oArtists = new OverlayArtist[1];
  oArtists[0] = createOverlayArtist("BlurOverlayArtist");
  oArtists[0].init(new Double(0.50));

  // Create LemurPoint objects
  createLemurPoints();
}

void draw()
{
  

  background(0);
  if (pArtist != null) pArtist.paint(pointSets[currentPreset]);
  
  gl.glBlendFunc(GL.GL_DST_COLOR, GL.GL_ZERO); // Switch to masking mode
  bgArtist.paint();
    
  // rect(0, 0, width, height);
  
  if (pMotion != null) {
	  pMotion.move(pointSets[currentPreset]);
	  /* comment out this line to turn off syncing the lemur points,
	    p* (you could still manually sync the lemur points with "p")
	  */
	  osc.sendPointsToOSC(pointSets[currentPreset]);  
  }
  
  
  
  //beat.drawGraph(this);
  for (int i = 0; i < oArtists.length; i++) {
    oArtists[i].paint();
  }
  
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA); // Disable masking
  
  // Display framerate
  text(frameRate, width-45, height-25);
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
      // connect/disconnect don't mean anything... can be ignored.
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
      osc.sendPointsToOSC(pointSets[currentPreset]);  
      break;
    case('q'):
      /* change point artist */
      pArtist = new PointArtist();
      break;
    case('m'):
      /* jump to a random place in the movie if it's being used as a background */
      // sosMovie.jump(random(sosMovie.duration()));
      //sosMovie.loop();
      ((MovieBackgroundArtist)bgArtist).init(sosMovie);
      //sosMovie.stop();
      break;
    case('n'):
      currentPreset +=1;
      if (currentPreset >= numPointSets) currentPreset = 0;
      osc.connectToPoints(pointSets[currentPreset]);
      break;
  }  
}

void createLemurPoints() {
  int a = 0;
  for (int j = 0; j < numPointSets; j++) {
    if (j == 0) {
      pointSets[j] = new LemurPoint[10];
      int xincrement = width / 2;
      int yincrement = height / 5;
      int[][] gridCoords = new int[10][2];
      int tempIndex = 0;
      translate(width / 3, height / 3);
      for (int y = 0; y < 5; y++) {
        for (int x = 0; x < 2; x++) {
           {
            gridCoords[tempIndex][0] = (x * xincrement) + (xincrement / 2);
            gridCoords[tempIndex][1] = (y * yincrement) + (yincrement / 2);
            tempIndex ++;
            print(x);
          }
        }
      }
      print(gridCoords);
      for (int i = 0; i < 10; i++) {
        pointSets[j][i] = new LemurPoint(beat, gridCoords[i][0], gridCoords[i][1], i);
        pointSets[j][i].setBand(i*2, i*2 + 3, 2);
      }
    } else {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        a = i + 1;
        pointSets[j][i] = new LemurPoint(beat, a*40, a*15, i);
        pointSets[j][i].setBand(i*2, i*2 + 3, 2);
      }
    }

  }    
  osc.connectToPoints(pointSets[currentPreset]);
}


/* incoming osc message are forwarded to the oscEvent method. */
void oscEvent(OscMessage theOscMessage) {
    osc.handleMessage(theOscMessage);
}



JMCMovieGL movieFromDataPath(String filename)
{
  return new JMCMovieGL(this, filename, RGB);
}

JMCMovieGL movieFromFile(String filename)
{
  return new JMCMovieGL(this, new File(filename), RGB);
}

JMCMovieGL movieFromURL(String urlname)
{
  URL url = null;

  try
  {
    url = new URL(urlname);
  }
  catch(Exception e)
  {
    println("URL error...");
  } 

  return new JMCMovieGL(this, url, RGB);
}

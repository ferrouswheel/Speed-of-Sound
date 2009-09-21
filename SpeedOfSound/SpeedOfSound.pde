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
Boolean applyThreshold = true;
Boolean useRorschach = false;
float thresh = 0.1;
Rorschach rorschachLayer;
GLGraphicsOffScreen rOffscreen;
GLTexture texDest;
GLTextureFilter threshhold;
// Movie sosMovie;

void setup()
{
  size(640, 360, GLConstants.GLGRAPHICS);  
  rOffscreen = new GLGraphicsOffScreen(this, width, height);
  texDest = new GLTexture(this, width, height);
  threshhold = new GLTextureFilter(this, "threshold.xml");
  // Fullscreen
  // size(screen.width, screen.height, GLConstants.GLGRAPHICS);
  // Processing seems to force 2x smooth if it's not explicitly disabled
  hint(DISABLE_OPENGL_2X_SMOOTH);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  gl = (( PGraphicsOpenGL )g).gl;
  gl.glEnable(GL.GL_LINE_SMOOTH);
  frameRate(60);
  smooth();
  colorMode(HSB);
  
  minim = new Minim(this);
  osc = new OSCConnection(this,"192.168.0.2",8000);
  song = minim.getLineIn(Minim.STEREO, 512);

  // a beat detection object that is FREQ_ENERGY mode that 
  // expects buffers the length of song's buffer size
  // and samples captured at songs's sample rate
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  // make a new beat listener, so that we won't miss any buffers for the analysis
  bl = new BeatListener(beat, song);
  beat.setSensitivity(400);

  textFont(createFont("SanSerif", 16));
  textAlign(CENTER);

  // TODO ensure all artists are created via the factory methods (e.g.
  // createBackgroundArtist() )

  // sosMovie = new Movie(this, "carnival2.mov");
  sosMovie = movieFromDataPath("fox.mov"); // JMC
  sosMovie.loop();
  bgArtist = createBackgroundArtist("MovieBackgroundArtist");
  bgArtist.init(sosMovie);

  pArtist = new PointArtist();
  pMotion = null; //new PointMotion();

  // // WITH waveformoverlay
  // oArtists = new OverlayArtist[2];
  // oArtists[0] = createOverlayArtist("WaveformOverlayArtist");
  // oArtists[0].init(song);
  // oArtists[1] = createOverlayArtist("BlurOverlayArtist");
  // oArtists[1].init(new Double(0.50));
  // WITHOUT
  oArtists = new OverlayArtist[1];
  oArtists[0] = createOverlayArtist("BlurOverlayArtist");
  oArtists[0].init(new Double(0.50));
  rorschachLayer = new Rorschach();

  // Create LemurPoint objects
  createLemurPoints();
}

void draw()
{
  
  gl.glEnable(GL.GL_LINE_SMOOTH);
  background(0);
  if (useRorschach) {
    rOffscreen.beginDraw();
    gl.glBlendFunc(GL.GL_ONE, GL.GL_ONE_MINUS_SRC_COLOR);
    rorschachLayer.paint();
    gl.glDisable(GL.GL_BLEND);
    // rOffscreen.filter(THRESHOLD,0.9);
    rOffscreen.endDraw();
    if (applyThreshold) {
      rOffscreen.getTexture().filter(threshhold, texDest);
      image(texDest, 0, 0);
    } else {
      image(rOffscreen.getTexture(), 0, 0);
    }

    
  } else {
    if (pArtist != null) pArtist.paint(pointSets[currentPreset]);
  }

  gl.glEnable(GL.GL_BLEND);
  gl.glBlendFunc(GL.GL_DST_COLOR, GL.GL_ZERO); // Switch to masking mode
  bgArtist.paint();
    
  // rect(0, 0, width, height);
  if (pMotion != null) {
	  pMotion.move(pointSets[currentPreset]);
	  osc.sendPointsToOSC(pointSets[currentPreset]);  
  }
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
    case('r'):
      useRorschach = !useRorschach;
      break;
    case('t'):
      applyThreshold = !applyThreshold;
      break;
    case('1'):
      rorschachLayer.movementMode = 0;
      break;
    case('2'):
      rorschachLayer.movementMode = 1;
      break;
    case('3'):
      rorschachLayer.movementMode = 2;
      break;
    case('4'):
      rorschachLayer.movementMode = 3;
      break;
    case('5'):
      rorschachLayer.movementMode = 4;
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
    if (j == 1) {
      pointSets[j] = new LemurPoint[10];
      int xincrement = width / 3;
      int yincrement = height / 3;
      int[][] gridCoords = new int[10][2];
      int tempIndex = 0;
      translate(width / 3, height / 3);
      for (int y = 0; y < 3; y++) {
        for (int x = 0; x < 3; x++) {
           {
            gridCoords[tempIndex][0] = (x * xincrement) + (xincrement / 2);
            gridCoords[tempIndex][1] = (y * yincrement) + (yincrement / 2);
            tempIndex ++;
            print(x);
          }
        }
      }
      for (int i = 0; i < 10; i++) {
        pointSets[j][i] = new LemurPoint(beat, gridCoords[i][0], gridCoords[i][1], i);
        pointSets[j][i].setBand(i*2, i*2 + 3, 2);
        if (i == 9) {
          pointSets[j][i].active = false;
        }
      }
    }
    else if (j == 0) {
      pMotion = new PointMotion();
      pMotion.mode = 2;
      pMotion.jumpDistance = 20;
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        a = i + 1;

        if (i == 0){
          pointSets[j][i] = new LemurPoint(beat, (width / 2 - 30), (height / 2), i);
          pointSets[j][i].partialAlpha = true;
          pointSets[j][i].setBand(i*2, i*2 + 3, 2);
        } else if (i == 1) {
          pointSets[j][i] = new LemurPoint(beat, (width / 2 + 30), (height / 2), i);
          pointSets[j][i].partialAlpha = true;
          pointSets[j][i].setBand(i*2, i*2 + 3, 2);
        }
        else {
          pointSets[j][i] = new LemurPoint(beat, (width - 100), (height / 2), i);
          pointSets[j][i].setBand(i*2, i*2 + 3, 2);
          pointSets[j][i].active = false;
        }
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

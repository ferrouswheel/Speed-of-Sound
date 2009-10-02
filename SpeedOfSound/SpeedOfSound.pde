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

/**

Known bugs:

Lemur sometimes stop responding to multiball updates for where the points are. Appears to be on the Lemur side,
and for now, the easiest fix is to restart the Lemur (everything else still works, it's just the point updates
on the Lemur that don't work).

Roscharch image corruption - sometimes the ball image doesn't paint correctly. Joel debugged the generateCircleImage
method, and it seems to be creating the image correctly when the contents of the image are printed to stdout.
Don't know where the corruption is occurring :-(

*/


// Config:
boolean debug = true;
// IP of the Lemur, Lemur should also be set up to send to the local IP on port 12000
String lemurIP = "10.9.8.172";
// This hasn't been implemented yet, but Will should put all JMC stuff in a separate BackgroundArtist
// and choose the BG artist based on this variable.
Boolean useJMC = false;
// Videos to use for movie background
// Videos should be of a small size... 180 by 144 or something similar, otherwise framerate gets killed
// This might not be the case with JMC video, but I'm not sure...
// TODO: Load this list of movies from the data directory
String[] vids = new String[]{"carnival_faces_small.avi", "carnival_motion_small.avi", "spin_lights2_small.avi",
      "spining1_small.avi", "spin_lights3_small.avi", "lights_spin3_small.avi", "carnival2_small.avi",
      "rollercoaster_small.avi", "spin_lights1_small.avi", "carnival_faces_small.avi",
      "crowd_lights1_small.avi", "dancing_costume_small.avi", "lights_loop1_small.avi", "lights_loop2_small.avi", 
    "lights_loop3_small.avi", "lights_loop4_small.avi", "lights_loop5_grid_small.avi", "lights_loop6_small.avi", 
    "lights_loop7_small.avi", "lights_loop8_small.avi",
    "lights_loop9_small.avi", "lights_loop10_small.avi",
    "lights_loop11_small.avi", "machines_small.avi",
    "plane2_multiply2.avi","plane2_multiply3.avi",
    "plane2a.avi","plane2aaa.avi",
    "plane3.avi","plane4.avi",
    "plane5.avi","plane5_multiply2.avi",
    "plane5_multiply3.avi","plane6.avi",
    "rocket1.avi","rocket2.avi","rocket3a.avi"
};

// Title movies, first is a coloured one suitable for a background, second is for overlays (black/white)
String titles[][] = {
  { null, null }, // "title_sos.avi"
  { null, "title_jetpilot.avi"},
  { null, "title_boy.avi"},
  { "title_kellective.avi", null}, 
  { null, "title_andy.avi"},
  { null, "title_perspexx.avi"},
  { null, "title_rich.avi"},
  { "title_aerialists.avi", "title_aerialists_white.avi"},
  { "title_aerialists_small.avi", null},
  { "title_andrea3.avi", "title_andrea_white.avi"},
  { "title_pipi.avi", "title_pipi_white.avi"},
  { "title_polly.avi", "title_polly_white.avi"},
  { "title_aaron.avi", "title_aaron_white.avi"},
};

// Gifs to use for GIF background
// TODO
// Images to use for image backgroun
// TODO
// List of camera devices to use.
String[] cameraNames = new String[] {
  //"AVerMedia 716x BDA Analog Capture-WDM", // For Joel's tv card input of handycam
  //"Logitech QuickCam Express/Go-WDM", // For Joel's cheap webcam
  "Laptop Integrated Webcam-WDM"

};

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

CamBackgroundArtist[] cameras;
//= new CamBackgroundArtist[2];

TitleBackgroundArtist titleArtist;

boolean overlayOn = true;

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

// When demo mode is on, this automatically progresses to new backgrounds, presets, etc.
boolean demoMode = false;
// No changes to a particular parameter will be made until this time.
int minTimeBeforeSwitch = 1000;
// Timer keeps track of when the last change happened, then after minTime the chance
// following is the likelihood of changing.
int presetTimer = 0; float presetChangeChance = 0.05;
int motionTimer = 0; float motionChangeChance = 0.1;
int backgroundTimer = 0; float backgroundChangeChance = 0.05;

Rorschach rorschachLayer; // An alternative to the PointArtist layer.

void setup()
{
  size(1024, 768, GLConstants.GLGRAPHICS);  
  // Fullscreen
  // size(screen.width, screen.height, GLConstants.GLGRAPHICS);
  // Processing seems to force 2x smooth if it's not explicitly disabled
  hint(DISABLE_OPENGL_2X_SMOOTH);
  hint(ENABLE_OPENGL_4X_SMOOTH);
  GL gl = (( PGraphicsOpenGL )g).gl;
  gl.glEnable(GL.GL_LINE_SMOOTH);
  frameRate(60);
  //frame.setResizable(true);
  smooth();
  colorMode(HSB);
  String[] devices = Capture.list();
  println(devices);
  
  minim = new Minim(this);
  osc = new OSCConnection(this,lemurIP,8000);
  song = minim.getLineIn(Minim.STEREO, 512);

  // a beat detection object that is FREQ_ENERGY mode that 
  // expects buffers the length of song's buffer size
  // and samples captured at songs's sample rate
  beat = new BeatDetect(song.bufferSize(), song.sampleRate());
  // make a new beat listener, so that we won't miss any buffers for the analysis
  bl = new BeatListener(beat, song);
  beat.setSensitivity(60);
 
  textFont(createFont("SanSerif", 16));
  textAlign(CENTER);
  
  // TODO ensure all artists are created via the factory methods (e.g.
  // createBackgroundArtist() )

  bgArtist = createBackgroundArtist("MovieBackgroundArtist");
  bgArtist.init(vids);
  
  titleArtist = new TitleBackgroundArtist(this);
  titleArtist.init(titles);

  // Initialise cameras
  cameras = new CamBackgroundArtist[cameraNames.length];
  for (int i = 0; i < cameras.length; i++) {
    cameras[i] = new CamBackgroundArtist(this, cameraNames[i]);
    //cameras[i].active = true;
  }
  
  // Initialise point artist
  pArtist = new PointArtist();
  pMotion = new PointMotion();

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
  rorschachLayer = new Rorschach(this);

  // Create LemurPoint objects
  createLemurPoints(true);
  
  osc.setAll(); // Set everything to its init point
}

void draw()
{
  background(0);
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
  GL gl = pgl.gl;

  titleArtist.paint(); // Needs to do video changes in paint method
  if (!titleArtist.playing) {
    if (overlayOn) {
      if (rorschachLayer.active) { // Simple switch. Use Rorschach or PointArtist
        rorschachLayer.paint();
      } else if (pArtist != null && pArtist.active) {
        pArtist.paint(pointSets[currentPreset]);
      }
    } else {
      background(255);
    }
  }

  gl.glEnable(GL.GL_BLEND); // Re-enable blending mode
  gl.glBlendFunc(GL.GL_DST_COLOR, GL.GL_ZERO); // Switch to masking mode
  bgArtist.paint(); // Movie rendered on white regions of screen

  for (int i = 0; i < cameras.length; i++) {
    if (cameras[i].active) cameras[i].paint();
  }
    
  if (pMotion != null && !rorschachLayer.active) {
    pMotion.move(pointSets[currentPreset]);
    osc.sendPointsToOSC(pointSets[currentPreset]);  
  }
  for (int i = 0; i < oArtists.length; i++) {
    oArtists[i].paint();
  }
  
  gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA); // Disable masking so framerate display is legible
  
  // Display framerate
  text(frameRate, width-45, height-25);
  gl.glDisable(GL.GL_BLEND); // Re-enable blending mode
  
  if (demoMode) {
    demoModeUpdate();
  }
}
    
void demoModeUpdate() {
    presetTimer++;
    motionTimer++;
    backgroundTimer++;
    if (presetTimer > minTimeBeforeSwitch) {
      if (random(1.0) < presetChangeChance) {
         // reset presets
         createLemurPoints(false);
         // random size
         pArtist.beatSize = (int) random(40, width / 2);
         pArtist.minSize = (int) random(0, pArtist.beatSize * 3 / 4);
         //currentPreset = (int) random(pointSets.length);
         currentPreset = (int) random(10); // other presets might not changed from boring starts
         if (currentPreset == 9) {
           pArtist.active = false;
         } else {
           pArtist.active = true;
         }
         
         presetTimer = 0;
      }
    }
    if (motionTimer > minTimeBeforeSwitch) {
      if (random(1.0) < motionChangeChance) {
         pMotion.setMode( (int) random(5) );
         motionTimer = 0;
         if (pMotion.mode == 4) { // Gravity
           pMotion.gProportion = random(-0.5, 0.5);
         }
      }
    }
    if (backgroundTimer > minTimeBeforeSwitch) {
      if (random(1.0) < backgroundChangeChance) {
         bgArtist.setCurrentSource((int) random(vids.length));
         backgroundTimer = 0;
      }
    }
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

void createLemurPoints (boolean booting) {
  int a = 0;
  for (int j = 0; j < numPointSets; j++) {
    if (j == 0) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        pointSets[j][i] = new LemurPoint(beat, (width / 10 * i) + (width / 20), (height / 10 * i) + (height / 20), i);
      }

    } else if (j == 1) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        if (i < 5) {
          pointSets[j][i] = new LemurPoint(beat, (width / 5 * i) + (width / 10), (height / 5 * i) + (height / 10), i);
        } else {
          int revHeight = (height / 5 * (i - 5)) + (height / 10);
          pointSets[j][i] = new LemurPoint(beat, (width / 5 * ( i - 5)) + (width / 10), (height - revHeight), i);
        }
      }

    } else if (j == 2) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        
        if (i == 0) { 
          pointSets[j][i] = new LemurPoint(beat, width / 2, (height / 2 - 100), i);
        } else if (i == 1) {
          pointSets[j][i] = new LemurPoint(beat, (width / 2 - 100), (height / 2 + 100), i);
        } else if (i == 2) {
          pointSets[j][i] = new LemurPoint(beat, (width / 2 + 100), (height / 2 + 100), i);
        } else {
          pointSets[j][i] = new LemurPoint(beat, 0, 0, i);
          pointSets[j][i].active = false;
        }
      }

    } else if (j == 3) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        pointSets[j][i] = new LemurPoint(beat, width / 2, height / 2, i);
        if (i > 0) {
          pointSets[j][i].active = false;
        }
      }

    } else if (j == 4) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        float angle = (((2 * PI) / 10) * (i));
        float x = (cos(angle) * 200) + (width / 2);
        float y = (sin(angle) * 200) + (height / 2);
        pointSets[j][i] = new LemurPoint(beat, int(round(x)), int(round(y)), i);
      }

    } else if (j == 5) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        pointSets[j][i] = new LemurPoint(beat, (((width / 10) * (i + 1)) - (width / 20)), height / 2, i);
        pointSets[j][i].setBand(i*2, i*2 + 3, 2);
        
      }

    } else if (j == 6) {
      pointSets[j] = new LemurPoint[10];
      for (int i = 0; i < 10; i++) {
        if (i == 0) {
          pointSets[j][i] = new LemurPoint(beat, width / 2, height / 2, i);
        } else if ( i == 1) {
          pointSets[j][i] = new LemurPoint(beat, (width / 2 - 100), height / 2, i);
        } else if ( i == 2) {
          pointSets[j][i] = new LemurPoint(beat, (width / 2 + 100), height / 2, i);
        } else {
          pointSets[j][i] = new LemurPoint(beat, 0, 0, i);
          pointSets[j][i].active = false;
        }
        pointSets[j][i].setBand(i*2, i*2 + 3, 2);
        
      }

    } else if (j == 7) {
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
    else if (j == 8) {
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
          pointSets[j][i] = new LemurPoint(beat, 0, 0, i);
          pointSets[j][i].setBand(i*2, i*2 + 3, 2);
          pointSets[j][i].active = false;
        }
      }
    } else if (booting) { // OTHER
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

/* // TODO: move all this into the JMC BackgroundArtist
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
*/

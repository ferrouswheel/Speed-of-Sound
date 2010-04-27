/**
 * Speed of Sound Visualiser with Lemur interface
 * by Joel Pitt, Kelly, Will Marshall
 *
 */

import jmcvideo.*;
import processing.video.*;
import processing.opengl.*;
import javax.media.opengl.*;
import javax.media.opengl.glu.*;
import codeanticode.glgraphics.*;
import java.nio.IntBuffer;

import ddf.minim.*;
import ddf.minim.analysis.*;

import oscP5.*;

/*

Known bugs:

Lemur sometimes stop responding to multiball updates for where the points are.
Appears to be on the Lemur side, and for now, the easiest fix is to restart the
Lemur (everything else still works, it's just the point updates on the Lemur
that don't work).

Roscharch image corruption - sometimes the ball image doesn't paint correctly.
Joel debugged the generateCircleImage method, and it seems to be creating the
image correctly when the contents of the image are printed to stdout.  Don't
know where the corruption is occurring :-(

*/


// Config:
boolean debug = true;

// IP of the Lemur, Lemur should also be set up to send to the local IP on port 12000
String lemurIP = "192.168.1.8"; //169.254.5.103"; //192.168.1.135"; //"169.254.5.103"; ////"10.9.8.172";

// Use JMC to play movies (you want this if you use a Mac, because QT java
// bindings are screwed and Apple refuses to fix them.
Boolean useJMC = true;

// Whether or not to display framerate
Boolean displayFramerate = true;

// Videos to use for movie background
// Videos should be of a small size... 180 by 144 or something similar, otherwise framerate gets killed
// This might not be the case with JMC video, but I'm not sure...
String moviePrefix = "vid_";

// = new String[]{"carnival_faces_small.avi", "carnival_motion_small.avi", "spin_lights2_small.avi",
//       "spining1_small.avi", "spin_lights3_small.avi", "lights_spin3_small.avi", "carnival2_small.avi",
//      "rollercoaster_small.avi", "spin_lights1_small.avi", "carnival_faces_small.avi",
//      "crowd_lights1_small.avi", "dancing_costume_small.avi", "lights_loop1_small.avi", "lights_loop2_small.avi", 
//    "lights_loop3_small.avi", "lights_loop4_small.avi", "lights_loop5_grid_small.avi", "lights_loop6_small.avi", 
//    "lights_loop7_small.avi", "lights_loop8_small.avi", "lights_loop12.avi", "lights_loop13.avi",
//    "lights_loop9_small.avi", "lights_loop10_small.avi",
//    "lights_loop11_small.avi", "machines_small.avi",
//    "plane2_multiply2.avi","plane2_multiply3.avi",
//    "plane2a.avi","plane2aaa.avi",
//    "plane3.avi","plane4.avi",
//    "plane5.avi","plane5_multiply2.avi",
//    "plane5_multiply3.avi","plane6.avi", "plane7.avi", "flying.avi",
//    "rocket1.avi","rocket2.avi","rocket3a.avi"
//     
//}; 

// Title movies, first is a coloured one suitable for a background, second is for overlays (black/white)
String titles[][] = {
  { null, "title-speedofsound.avi" }, // "title_sos.avi"
  { null, "title_jetpilot.avi"},
  { null, "title_boy.avi"},
  { "title_kellective.avi", "title-kellective2.avi"}, 
  { null, "title_andy.avi"},
  { null, "title_perspexx.avi"},
  { null, "title_rich.avi"},
  { "title_aerialists.avi", "title_aerialists_white.avi"},
  { "title_aerialists_small.avi", null},
  { "title_andrea3.avi", "title_andrea_white.avi"},
  { "title_pipi.avi", "title_pipi_white.avi"},
  { "title_polly.avi", "title_polly_white.avi"},
  { "title_aaron.avi", "title_aaron_white.avi"},
  { null, "title-happyinmotion.avi"},
};

// Gifs to use for GIF background
// TODO
// Images to use for image backgroun
// TODO

// When Speed of Sound starts up it will list the Camera devices available.
// You should add those you want to use to this array.
// List of camera devices to use.
String[] cameraNames = new String[] {
  "USB Video Class Camera" // MBP webcam
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

// Whether an accumulation buffer was detected
Boolean accumBufferExists = true;

Rorschach rorschachLayer; // An alternative to the PointArtist layer.

Boolean checkAccumulationBuffer()
{
  int ab[] = new int[4];
  gl.glGetIntegerv(gl.GL_ACCUM_RED_BITS,ab, 0);
  gl.glGetIntegerv(gl.GL_ACCUM_GREEN_BITS,ab, 1);
  gl.glGetIntegerv(gl.GL_ACCUM_BLUE_BITS,ab, 2);
  gl.glGetIntegerv(gl.GL_ACCUM_BLUE_BITS,ab, 3);
  print("Accumulation buffer bits: ");
  for (int j=0; j < 4; j++) {
      if (ab[j] == 0) accumBufferExists = false;
      print(ab[j]); print(" ");
  }
  println("");
  if (!accumBufferExists) println("Accumulation buffer not supported");
  return accumBufferExists;

}

void initCameras()
{
  String[] devices = Capture.list();
  println("Camera devices detected");
  println(devices);
  // Initialise cameras in cameraNames, but only if they were detected
  cameras = new CamBackgroundArtist[cameraNames.length];
  for (int i = 0; i < cameraNames.length; i++) {
    cameras[i] = null;
    for (int j = 0; j < devices.length; j++) {
	if (cameraNames[i] == devices[j]) {
	    cameras[i] = new CamBackgroundArtist(this, cameraNames[i]);
	    j = devices.length;
	}
    }
  }
  println("Cameras initialised");
}

void setup()
{
  size(1024, 768, GLConstants.GLGRAPHICS);  
  // Fullscreen
  // size(screen.width, screen.height, GLConstants.GLGRAPHICS);
  // Processing seems to force 2x smooth if it's not explicitly disabled
   hint(DISABLE_OPENGL_2X_SMOOTH);
   hint(ENABLE_OPENGL_4X_SMOOTH);
  gl = (( PGraphicsOpenGL )g).gl;
  //gl.glEnable(GL.GL_LINE_SMOOTH);
  checkAccumulationBuffer();
  //gl.glReadBuffer(GL_FRONT);
  //gl.glCopyPixels(0,0,1024,768,gl.GL_COLOR);
  GLCapabilities c = ((GLGraphics)g).getCapabilities();
  println(c.toString());

  if (gl.isExtensionAvailable("GL_ARB_shading_language_100"))
      println( "Found GLSL shader language");

  //frameRate(60);
  //frame.setResizable(true);
  //smooth();
  //colorMode(HSB);
  
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
  bgArtist.init(moviePrefix);
  
  titleArtist = new TitleBackgroundArtist(this);
  titleArtist.init(titles);

  initCameras();
  
  // Initialise point artist
  pArtist = new PointArtist();
  pMotion = new PointMotion();

  oArtists = new OverlayArtist[0];
  // // WITH waveformoverlay
  // oArtists[0] = createOverlayArtist("WaveformOverlayArtist");
  // oArtists[0].init(song);
  if (accumBufferExists) {
      oArtists = new OverlayArtist[1];
      oArtists[0] = createOverlayArtist("BlurOverlayArtist");
      oArtists[0].init(new Double(0.90));
  }
  rorschachLayer = new Rorschach(this);

  // Create LemurPoint objects
  createLemurPoints(true);
  
  osc.setAll(); // Set everything to its init point
  //cameras[0].active = true;
  println("Finished initialisation");
}

void draw()
{
  background(0);
  PGraphicsOpenGL pgl = (PGraphicsOpenGL) g;
  GL gl = pgl.gl;

  titleArtist.paint(); // Needs to do video changes in paint method
  if (!(titleArtist.playing)) {
      if (rorschachLayer.active && rorschachLayer.overlay) { // Simple switch. Use Rorschach or PointArtist
	gl.glEnable(GL.GL_BLEND); // Enable blending mode
        gl.glBlendFunc(GL.GL_ONE, GL.GL_ONE_MINUS_SRC_COLOR);
	rorschachLayer.paint();
	gl.glDisable(GL.GL_BLEND); // Enable blending mode
      }
      if (pArtist.active && pArtist.overlay) {
        pArtist.paint(pointSets[currentPreset]);
      }
      /*if (!(pArtist.active && pArtist.overlay) &&
          !(rorschachLayer.active && rorshachLayer.overlay)) {
        background(255);
      }*/
  }
  boolean blendTime = (pArtist.active && pArtist.overlay) ||
          (rorschachLayer.active && rorschachLayer.overlay) ||
          (titleArtist.playing && titleArtist.isOverlay == 1);
  if (blendTime) {
    gl.glEnable(GL.GL_BLEND); // Enable blending mode
    gl.glBlendFunc(GL.GL_DST_COLOR, GL.GL_ZERO); // Switch to masking mode
  }

  if (!titleArtist.playing || titleArtist.isOverlay == 1) {
    bgArtist.paint(); // Movie rendered on white regions of screen
  }
  
  if (!titleArtist.playing) {
   gl.glEnable(GL.GL_BLEND); // Re-enable blending mode
   gl.glBlendFunc(GL.GL_DST_COLOR, GL.GL_ZERO); // Switch to video blending mode
  }
  
  if (!titleArtist.playing || titleArtist.isOverlay == 1) {
    for (int i = 0; i < cameras.length; i++) {
      if (cameras[i] != null && cameras[i].active) cameras[i].paint();
    }
  }
  
  // Switch to respect alpha transparency. DEFAULT BLENDING MOE FOR ALPHA PNGS ETC
  if (!titleArtist.playing) {
   gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_ONE_MINUS_SRC_ALPHA);
  }

  // Simple switch. Use Rorschach or PointArtist
  if (rorschachLayer.active && !rorschachLayer.overlay) {
     rorschachLayer.paint();
  }
  if (pArtist.active && !pArtist.overlay) {
     pArtist.paint(pointSets[currentPreset]);
  }
 
  if (pMotion != null) {
    pMotion.move(pointSets[currentPreset]);
    osc.sendPointsToOSC(pointSets[currentPreset]);  
  }
  for (int i = 0; i < oArtists.length; i++) {
    oArtists[i].paint();
  }
  
  if (displayFramerate) {
    if (blendTime) {
	gl.glBlendFunc(GL.GL_SRC_ALPHA, GL.GL_DST_ALPHA); // Disable masking so framerate display is legible
    }
    // Display framerate - this crashes the app after a random interval, so disable it for performance.
    // text(frameRate, width-45, height-25);
  }
  if (blendTime) {
    gl.glDisable(GL.GL_BLEND);
  }
  
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
         int p = (int) random(10); // other presets might not changed from boring starts
         if (p == 9) {
           pArtist.active = false;
           pArtist.oscSendActive(osc.oscP5, osc.oscDestination);
         } else {
           pArtist.active = true;
           pArtist.oscSendActive(osc.oscP5, osc.oscDestination);
           osc.changePreset(p);
         }
         
         presetTimer = 0;
      }
    }
    if (motionTimer > minTimeBeforeSwitch) {
      if (random(1.0) < motionChangeChance) {
         pMotion.setMode( (int) random(5) );
         pMotion.oscSendMode(osc.oscP5, osc.oscDestination);
         motionTimer = 0;
         if (pMotion.mode == 4) { // Gravity
           pMotion.gProportion = random(-0.5, 0.5);
         }
      }
    }
    if (backgroundTimer > minTimeBeforeSwitch) {
      if (random(1.0) < backgroundChangeChance) {
         bgArtist.setCurrentSource((int) random(bgArtist.getNumberOfSources()));
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


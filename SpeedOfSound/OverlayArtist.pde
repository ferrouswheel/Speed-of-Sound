class OverlayArtist {

    OverlayArtist() {
    }

    void paint() {}
}

class BlurOverlayArtist extends OverlayArtist {
    float v = 1.0/9.0;
    float[][] kernel = { { v, v, v },
                         { v, v, v },
                         { v, v, v } };

    BlurOverlayArtist() {
    }

    void paint() {
        loadPixels();
        // Loop through every pixel in the image.
        for (int y = 1; y < height-1; y++) { // Skip top and bottom edges
          for (int x = 1; x < width-1; x++) { // Skip left and right edges
            float sum = 0; // Kernel sum for this pixel
            for (int ky = -1; ky <= 1; ky++) {
              for (int kx = -1; kx <= 1; kx++) {
                // Calculate the adjacent pixel for this kernel point
                int pos = (y + ky)*width + (x + kx);
                // Image is grayscale, red/green/blue are identical
                float val = red(pixels[pos]);
                // Multiply adjacent pixels based on the kernel values
                sum += kernel[ky+1][kx+1] * val;
              }
            }
            // For this pixel in the new image, set the gray value
            // based on the sum from the kernel
            pixels[y*width + x] = color(sum);
          }
        }
        // State that there are changes to edgeImg.pixels[]
        updatePixels();
    }
}

// Normally the below would go in a separate Factory class, but Processing makes
// everythin an inner class, which prevents us having static methods.
String[] overlayArtistTypes = {
    "None",
    "BlurOverlayArtist"
};


OverlayArtist createOverlayArtist(String t) {
    if (t.equals("BlurOverlayArtist")) {
        return new BlurOverlayArtist();
	// uncomment these when they are implemented
	//case ImageBgArtist:
    //      return new ImageBgArtist();
     //   case MovieBgArtist:
    //      return new MovieBgArtist();
	    
    } else {
        println("Unknown or unimplemented artist type");
        return null;
    }
}

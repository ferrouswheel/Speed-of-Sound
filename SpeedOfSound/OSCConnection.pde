import oscP5.*;
import netP5.*;


class OSCConnection {
    public OscP5 oscP5;
    /* a NetAddress contains the ip address and port number of a remote location in the network. */
    public NetAddress oscDestination; 
    LemurPoint[] points;

    OSCConnection (Object theParent, String server, int port) {
        /* create a new instance of oscP5. 
        * 12000 is the port number you are listening for incoming osc messages.
        */
        oscP5 = new OscP5(theParent,12000);

        /* create a new NetAddress. a NetAddress is used when sending osc messages
        * with the oscP5.send method.
        */

        /* the address of the osc broadcast server */
        oscDestination = new NetAddress(server,port);
    }

    void sendPointsToOSC(LemurPoint[] points) {
        /* Update lemur with the new points.. important for visualisation that
         * move the points around (but lemur physics should be turned off)
         */

        //for (LemurPoint p : points) {
        for (int i = 0; i < points.length; i++) {
            LemurPoint p = points[i];
            // Base path
            String pointPath = new String("/point" + p.index + "/");
            // send x,y coordinates
            OscMessage myOscMessage = new OscMessage(pointPath + "xy");
            int[] xy = {p.x, p.y};
            /* add a value (an integer) to the OscMessage */
            myOscMessage.add(xy);
            /* send the OscMessage to a remote location specified in myNetAddress */
            oscP5.send(myOscMessage, oscDestination);
        }
    }

    void connectToPoints(LemurPoint[] points) {
        this.points = points;
    }

    void updateX(int i, float x) {
        if (points != null && i < points.length) {
            points[i].x = (int) (x * width);
        }
    }

    void updateY(int i, float y) {
        if (points != null && i < points.length) {
            points[i].y = (int) ( (1.0 - y) * height);
        }
    }

    void handleMessage(OscMessage theOscMessage) {
        String path = theOscMessage.addrPattern();
        /* get and print the address pattern and the typetag of the received OscMessage */
        println("SOS received an osc message with addrpattern "+path+" and typetag "+theOscMessage.typetag());
        theOscMessage.print();
        if (path.substring(1,7).equals("points")) {
            //int pIndex = Integer.parseInt(path.substring(6,path.indexOf("/",6)));
            String property = path.substring(path.indexOf("/",7)+1);
            println("property = " + property);
            if (property.equals("x")) {
                int pointCount = theOscMessage.typetag().length();
                println("points = " + pointCount);
                for (int i = 0; i < pointCount; i++) {
                    float x = theOscMessage.get(i).floatValue();
                    updateX(i,x);
                }
            } else if (property.equals("y")) {
                int pointCount = theOscMessage.typetag().length();
                println("points = " + pointCount);
                for (int i = 0; i < pointCount; i++) {
                    float y = theOscMessage.get(i).floatValue();
                    updateY(i,y);
                }
            }
        }
    }

}

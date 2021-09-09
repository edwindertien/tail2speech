//////////////////////////////////////////////////////////////////////////////////
// Staart-sensor voor dog-to-speech
// werkt met Bluetooth sensor (accelerometer op WEMOS ESP32 board)
// krijgt twee coordinaten: X (kwispelen links-rechts) en Z (staart hoog/laag)
//
// vul hier de naam in voor de gebruikte sampleset:
String voice = "jazz"; // evi, lily, merel, myla, riv, jazz
// en of je een groot (akai apc mini) of klein (akai sampler) paneel gebruikt
String panel = "big"; // big or small

int timeoutvalue = 50;

// tail up wag   | ++  | blij
// tail up       | +   | geinteresseerd
// tail down wag | +/- | ok
// tail neutral  | -   | ontspannen
// tail down     | --  | negatief
// _______________________________________________________________________________
// E.Dertien -  (cc) 2021
//////////////////////////////////////////////////////////////////////////////////
import processing.serial.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

import themidibus.*; //Import the library
MidiBus myBus; // The MidiBus

AudioSample plusplus[] = new AudioSample[5];
AudioSample plus[] = new AudioSample[5];
AudioSample plusmin[] = new AudioSample[5];
AudioSample min[] = new AudioSample[5];
AudioSample minmin[] = new AudioSample[5];

int WINDOW = 128;

float xValues[] = new float[512];
float yValues[] = new float[512];
float fftWindow[] = new float[WINDOW];
Minim       minim;
AudioPlayer jingle;
FFT         fft;

int state = 0;
int preState = 0;

int channels[] = {0, 1};  // select the channels [0..5] to print, any number, max 6
int PORTNUMBER = 1;          // select the correct portnumber from the printed list
int gridlines = 1;           // on/off for printing gridlines
int scaling = 4;             // default: [0..1023] is mapped to [0..255]
Serial port;                 // port object for serial communication
String buff = "";            // input buffer for serial data
int NEWLINE = '\n';          // terminator of the serial commands
char header[] = {  'A', 'B', 'C', 'X', 'Y', 'Z'}; // headers for the values
int linecolor[] = {0, 40, 80, 120, 160, 200};     // colors for the lines (HSB)
PFont fontA;                 // screen font
int value[] = new int[6];    // array of current received values
int diffValue[] = new int[6];// array of previously received values
PrintWriter output;          // use file output
String outputBuff = "";      // buffer for file output
int filenr;                  // current file (incremental while the sketch is running)
int offset = 0;              // default: no offset in graph
float timescaling = 1.0;     // default: (1.0) = 25 sec time/per window
float amplitude = 1.0;       // default: (1.0) = 0..5 V range per window
String mode="RUN";           // mode can be RUN, PAUSE or RECORD
float n=21;                  // reset cursor position to 21.. 

void setup() {
  size(533, 286);
  println("Available serial ports:");
  for (int i = 0; i<Serial.list ().length; i++) { 
    print("[" + i + "] ");
    println(Serial.list()[i]);
  }
  port = new Serial(this, Serial.list()[PORTNUMBER], 9600);

  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.
  myBus = new MidiBus(this, 1, 3); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.

  frameRate(20);  // delay of 50 ms, 20Hz update
  minim = new Minim(this);
  fft = new FFT( WINDOW, 100 );
  colorMode(HSB);
  fontA = loadFont("SansSerif-10.vlw");
  textFont(fontA, 10);

  drawscreen();
  port.write(1);  // sometimes necessary to get the serial communication starting...

  for (int i = 0; i<5; i++) {
    plus[i] = minim.loadSample( voice+"/plus_"+ (i+1) + ".mp3", 512);
    minmin[i] = minim.loadSample( voice+"/minmin_"+ (i+1) + ".mp3", 512);
    plusplus[i] = minim.loadSample( voice+"/plusplus_"+ (i+1) + ".mp3", 512);
    min[i] = minim.loadSample( voice+"/min_"+ (i+1) + ".mp3", 512);
    plusmin[i] = minim.loadSample (voice+"/plusmin_"+ (i+1) + ".mp3", 512);
  }
}
int topvalue = 0;
int timeout = 0;
void draw() {
  while (port.available () > 0) {
    serialEvent(port.read()); // read data
  }

  drawscreen();
  outputBuff="" + millis();
  stroke(255);            // clear the space for the time
  fill(255);              // clear the space for the time
  rect(300, 0, 230, 12);  // clear the space for the time
  stroke(0);
  fill(0);
  text("time "+(millis()-500)/1000.0 +" s", 300, 12); // print actual time
  if (mode=="RUN") text("Automatic", 400, 12);
  else text("sample only", 400, 12);

  for (int k= 0; k<511; k++) {
    stroke(255, 255, 255);
    if (k>0) line(k-1+21, xValues[k-1]/4, k+21, xValues[k]/4);
  }
  for (int k= 0; k<511; k++) {
    stroke(200, 255, 255);
    if (k>0) line(k-1+21, yValues[k-1]/4, k+21, yValues[k]/4);
  }

  for (int z = 0; z<WINDOW; z++) {
    fftWindow[z] = xValues[abs(pointer-z)%512];
  }

  fft.forward( fftWindow );

  rect(400, 70, 129, 150);
  topvalue = 0;
  for (int i = 1; i < fft.specSize(); i++)
  {
    // draw the line for frequency band i, scaling it up a bit so we can see it
    stroke(255, 255, 255);
    line( 400+i*2, 220, 400+i*2, 220-fft.getBand(i)/200 );

    if (i>2 && fft.getBand(i)>4000) {
      if (fft.getBand(i)>fft.getBand(i-1)) topvalue = i;
      stroke(128);
      line(400+topvalue*2, 220, 400+topvalue*2, 70);
      //println(fft.getBand(i)/200);
    }
  }
  for (int k= 0; k<300; k++) {
    stroke(100, 255, 255);
    if (k>0) line(k-1+21, (height-topvalue*10)+10, k+21, (height-topvalue*10)+10);
  }
  if (mode=="RUN") {
    if (yValues[pointer]<(512-100) && state !=1 && topvalue<3 && timeout==0) {
      state = 1;
      timeout = 30;
      println("negative --");
      minmin[(int)random(5)].trigger();
    } else if (yValues[pointer]>(512+100) && state !=3 && topvalue>3 && timeout==0) {
      state = 3;
      timeout = timeoutvalue;
      println("positive ++");
      plusplus[(int)random(5)].trigger();
    } else if (yValues[pointer]>(512+100) && state !=2 && topvalue<3 && timeout==0) {
      state = 2;
      timeout = timeoutvalue;
      println("positive +");
      plus[(int)random(5)].trigger();
    } else if (yValues[pointer]<(512-100) && state !=4 && topvalue>3 && timeout==0) {
      state = 4;
      timeout = timeoutvalue;
      println("plus +");
      plus[(int)random(5)].trigger();
    } else if (yValues[pointer]<(512+100) && yValues[pointer]>(512-100) && state !=0 && timeout ==0) {
      state = 0;
      timeout = timeoutvalue;
      println("neutral +/-");
      plusmin[(int)random(5)].trigger();
    }
  }
  if (timeout>0) timeout --;
  //println(state);
  preState = state;
}
void drawscreen() {
  background(255);

  stroke(255, 0, 0);
  line(20, height-11, width, height-11);
  line(20, 13, width, 13);
  line(20, 0, 20, height);
  fill(255, 0, 0);
  text("0.0", 2, height-7-offset);
  text(nf(2.5/amplitude, 1, 1), 2, (height/2+7)-offset);
  text(nf(5.0/amplitude, 1, 1), 2, 23-offset);
  text("amplitude x "+nf(amplitude, 1, 1), 50, 12);
  text("time x "+nf(timescaling, 1, 1), 150, 12);
  text("offset "+offset+ " px", 220, 12);
  text("0 (s)", 21, height-1);
  for (int n=0; n<6; n++) {
    text(nf((5*n)/timescaling, 0, 0), 100*n+21, height-1);
  }
  if (gridlines>0) {
    stroke(200);                                 // use grey lines 
    for (float q=19; q<280; q+=25.5) {           // draw grid 
      line(21, 0+q-offset, width, 0+q-offset);   // horizontal grid lines
    } 
    for (int q=20; q<520; q+=20) {               //vertical grid lines 
      line(20+q, 14, 20+q, 274);
    }
  }
}
int pointer;
void serialEvent(int serial) { 
  try {                         // try-catch because of transmission errors
    if (serial != NEWLINE) { 
      buff += char(serial);
    } else {
      buff = buff.substring(0, buff.length()-1); // Parse the String into an integer
      int[] values = int(split(buff, ','));
      pointer++;
      if (pointer>511) pointer = 0;
      xValues[pointer] = values[0];
      yValues[pointer] = values[1];

      buff = "";                // Clear the value of "buff"
    }
  }

  catch(Exception e) {
    println("no valid data");
  }
}
void keyPressed() {
  if (key==' ' && mode=="RUN") mode="PAUSE";
  else if (key==' ' && mode=="PAUSE") mode="RUN";
  if (key=='r' && mode!="RECORD") {
    mode="RECORD";
    print("Start recording...");
    filenr++;
    output = createWriter("values"+filenr+".txt");
  }
  if (key=='s' && mode=="RECORD") {
    mode="STOP";
    println("ready!");
    output.flush(); // Write the remaining data
    output.close(); // Finish the file
  }
  if (key=='c') {
    n=21; 
    background(255);
  }
  if (key=='1' && amplitude>0.11) amplitude -=0.1;
  if (key=='2') amplitude +=0.1;
  if (key=='3' && timescaling > 0.11) timescaling -=0.1;
  if (key=='4') timescaling +=0.1;
  if (key=='5') offset -=1;
  if (key=='6') offset +=1;

  background(255); // clear screen
  drawscreen();    // redraw axes
}

void noteOn(int channel, int pitch, int velocity) {
  // Receive a noteOn
  println();
  println("Note On:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
if(panel=="big"){
  for (int i = 0; i<5; i++) {
    if (pitch==56+i) plusplus[i].trigger();
    if (pitch==48+i) plus[i].trigger();
    if (pitch==40+i) plusmin[i].trigger();
    if (pitch==32+i) min[i].trigger();
    if (pitch==24+i) minmin[i].trigger();
  }}

  else{if (pitch==36) plusmin[(int)random(5)].trigger();
   if (pitch==37) plusmin[1].trigger();
   if (pitch==38) plusmin[2].trigger();
   if (pitch==39) plusmin[3].trigger();
   if (pitch==40) plusplus[(int)random(5)].trigger();
   if (pitch==41) plus[(int)random(5)].trigger();
   if (pitch==42) min[(int)random(5)].trigger();
   if (pitch==43) minmin[(int)random(5)].trigger();
  }
}

void noteOff(int channel, int pitch, int velocity) {
  // Receive a noteOff
  println();
  println("Note Off:");
  println("--------");
  println("Channel:"+channel);
  println("Pitch:"+pitch);
  println("Velocity:"+velocity);
}

void controllerChange(int channel, int number, int value) {
  // Receive a controllerChange
  println();
  println("Controller Change:");
  println("--------");
  println("Channel:"+channel);
  println("Number:"+number);
  println("Value:"+value);
  if (number!=53 && number!=27)myBus.sendControllerChange(channel, number, value);
}

import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import ddf.minim.*; 
import ddf.minim.analysis.*; 
import java.io.*; 
import processing.serial.*; 
import java.util.*; 
import java.util.concurrent.LinkedBlockingQueue; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class audioVisualizer extends PApplet {







Minim minim;
AudioPlayer song;
AudioMetaData meta;
FFT fft;

float specLow = 0.03f; // 3%
float specMid = 0.125f;  // 12.5%
float specHi = 0.20f; // 20%

float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;
float scoreGlobal = 0;

// Valeur précédentes, pour adoucir la reduction
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

// Valeur d'adoucissement
float scoreDecreaseRate = 25;

int w = 900, h = 700;

int backgroundRate = 20;
int backgroundCount = 1;

long lastTime = System.currentTimeMillis();
long startTime = 0;

ArrayList<Spot> spots;
List<File> songFiles;
int songIndex = 0;

public void setup() {
  minim = new Minim(this);
  selectFolder("Select a file to process:", "folderSelected");
  //Load song
  
  spots = new ArrayList<Spot>(1000);
  surface.setResizable(true);
}

public void folderSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    System.exit(0);
  } else {
    println("User selected folder " + selection.getAbsolutePath());
    songFiles = new LinkedList<File>();
    File[] files = selection.listFiles();
    if (files != null && files.length != 0) {
       for (File file : files) {
         if (!file.isDirectory()) {
           String extension = getFileExtension(file);
           if (extension.equals("mp3") || extension.equals("wav") ){
              songFiles.add(file); 
           }
         }
       }
       
       Collections.sort(songFiles, new Comparator<File>() {
         @Override
         public int compare(final File f1, final File f2) {
           return f1.getName().compareToIgnoreCase(f2.getName());
         }
       });
       
       setupSong(songFiles.get(songIndex));
    } else {
      println("Problem getting files list in directory"); 
    }
  }
}

public String getFileExtension(File file) {
  String extension = "";

  int i = file.getPath().lastIndexOf('.');
  if (i > 0) {
      extension = file.getPath().substring(i+1);
  } 
  
  return extension;
}

public void setupSong(File selection) {
  try {
    song = minim.loadFile(selection.getAbsolutePath());
    meta = song.getMetaData();
    fft = new FFT(song.bufferSize(), song.sampleRate());
    song.play();
  } catch (Exception e) {
    try {
      song = minim.loadFile(selection.getAbsolutePath());
      meta = song.getMetaData();
      fft = new FFT(song.bufferSize(), song.sampleRate());
      song.play();
    } catch (Exception e1) {
      println("Error playing song");
    }
  }
}

public void draw() {
  if (backgroundCount % backgroundRate == 0) {
    background(215);
    backgroundCount = 1;
  }
  backgroundCount++;
  
  if (fft != null && song != null) {
    fft.forward(song.mix);
    
    oldScoreLow = scoreLow;
    oldScoreMid = scoreMid;
    oldScoreHi = scoreHi;
    
    //Réinitialiser les valeurs
    scoreLow = 0;
    scoreMid = 0;
    scoreHi = 0;
   
    //Calculer les nouveaux "scores"
    for(int i = 0; i < fft.specSize()*specLow; i++)
    {
      scoreLow += fft.getBand(i);
    }
    
    for(int i = (int)(fft.specSize()*specLow); i < fft.specSize()*specMid; i++)
    {
      scoreMid += fft.getBand(i);
    }
    
    for(int i = (int)(fft.specSize()*specMid); i < fft.specSize()*specHi; i++)
    {
      scoreHi += fft.getBand(i);
    }
    
    //Faire ralentir la descente.
    if (oldScoreLow > scoreLow) {
      scoreLow = oldScoreLow - scoreDecreaseRate;
    }
    
    if (oldScoreMid > scoreMid) {
      scoreMid = oldScoreMid - scoreDecreaseRate;
    }
    
    if (oldScoreHi > scoreHi) {
      scoreHi = oldScoreHi - scoreDecreaseRate;
    }
    
    //Volume pour toutes les fréquences à ce moment, avec les sons plus haut plus importants.
    //Cela permet à l'animation d'aller plus vite pour les sons plus aigus, qu'on remarque plus
    scoreGlobal = 0.66f*scoreLow + 0.8f*scoreMid + 1*scoreHi;
  
    simpleCircularFFTDisplay2();
    slowCircularFFTDisplay();
    
    for (Spot spot : spots) {
      beginShape ();
      //strokeWeight(2);
      spot.render();
      endShape ();
    }
    
    textSize(16);
    text(meta.title() + ", " + meta.author(), 10, height - 20); 
    fill(0, 102, 153);
    
    if (!song.isPlaying()) {
      songIndex++;
      if (songIndex == songFiles.size()) {
        songIndex = 0; 
      }
      setupSong(songFiles.get(songIndex)); 
    } else if (nextSong) {
      nextSong = false; 
      song.pause();      
    } else if (prevSong) {
      prevSong = false; 
      songIndex--;
      if (songIndex == -1) {
        songIndex = songFiles.size() - 1; 
      }
      song.pause();
      setupSong(songFiles.get(songIndex)); 
    }
  } else {
    background(255);
    startTime = System.currentTimeMillis(); 
  }
}

boolean nextSong = false, prevSong = false;
public void keyPressed() {
  if (keyCode == RIGHT) {
    nextSong = true;
  }else if (keyCode == LEFT) {
    prevSong = true;
  }
}


float startAngle = 0;

public void slowCircularFFTDisplay() {
  int maxTime = 18; //Seconds
  int numPoints = 2 * maxTime; //Data points for whole circle. Default is 2 points per second
  
  long timeDelta = System.currentTimeMillis() - lastTime;
  float timeDeltaSec = ((float) timeDelta) / 1000.0f;
  
  float angle = 2 * (float) Math.PI / numPoints * timeDeltaSec;
  
  if (angle >= 2 * (float) Math.PI) {
    lastTime = System.currentTimeMillis();
    angle = 0;
    spots.clear();
  }
  
  float centerX = width / 2, centerY = height / 2;
  float offsetCenterX = scoreGlobal / 12 * cos(angle);
  float offsetCenterY = scoreGlobal / 12 * sin(angle); 
  strokeWeight(4);
  stroke(scoreLow / 5, scoreMid / 5, scoreHi / 5);
  //point(centerX + offsetCenterX, centerY + offsetCenterY);
  
  float upperX = width * 0.80f, upperY = height * 0.20f, lowerX = width * 0.20f, lowerY = height * 0.80f;
  spots.add(new Spot(upperX + offsetCenterX, upperY + offsetCenterY, scoreLow / 5, scoreMid / 5, scoreHi / 5));
  spots.add(new Spot(lowerX + offsetCenterX, lowerY + offsetCenterY, scoreLow / 5, scoreMid / 5, scoreHi / 5));
}

float tempMax = 0, tempMin = 100000000.0f;


float lastX = 0, lastY = 0;


public void simpleCircularFFTDisplay2() {
  float timeOffset = System.currentTimeMillis() - startTime;
  
  for (int i = 0; i < fft.specSize()*specHi; i++) {
    float angle = 2 * (float) Math.PI / fft.specSize() / specHi * i + (timeOffset / 5000.0f);
    float centerX = width / 2, centerY = height / 2;
    float offsetCenterX = scoreGlobal / 8 * cos(angle);
    float offsetCenterY = scoreGlobal / 8 * sin(angle); 
    
    float band = fft.getBand(i);
    if (i < fft.specSize() * specLow) {
      band = 0.66f * band;
    } else if (i > fft.specSize() * specLow && i < fft.specSize() * specMid) {
      band = 0.8f * band;
    } else {
      band = 1* band; 
    }
    float lowerOffsetX = offsetCenterX - band * cos(angle);
    float lowerOffsetY = offsetCenterY - band * sin(angle);
    float upperOffsetX = offsetCenterX + band * cos(angle);
    float upperOffsetY = offsetCenterY + band * sin(angle);
    
    //-lowerOffsetX = min(lowerOffsetX, offsetCenterX / 2);
    
    strokeWeight(4);
    //point(centerX + offsetCenterX, centerY + offsetCenterY);
    
    strokeWeight(2);
    stroke(scoreLow / 5, scoreMid / 5, scoreHi / 5, scoreGlobal / 15);
    line(centerX + lowerOffsetX, centerY + lowerOffsetY, centerX + upperOffsetX, centerY + upperOffsetY);
  }
}


class BeatDetection {
  
 private BeatDetect beat;
 private AudioPlayer song;
 private LinkedBlockingQueue<Boolean> onsetQueue;
 
 private int averageBPM = 10;
 
 private int beatCount = 0;
 
 private long lastTime = System.currentTimeMillis();
 
 private final int sampleTime = 5000;
  
 public BeatDetection(AudioPlayer song) {
   beat = new BeatDetect();
   this.song = song;
   this.onsetQueue = new LinkedBlockingQueue<Boolean>(6);
 }
 
 public void update() {
   this.beat.detect(this.song.mix);
   
   if (System.currentTimeMillis() - lastTime > sampleTime) {
     int val = PApplet.parseInt(60.0f / ((float) sampleTime / 1000.0f)* (float) beatCount);
     averageBPM = max(10, val);
     
     //System.out.println("Timeout: " + beatCount);
     //System.out.println("BPM: " + val);
     
     this.beatCount = 0;
     lastTime = System.currentTimeMillis();
   } else {
     if (this.beat.isOnset() ){
       //System.out.println("Beatcount: " + this.beatCount);
       int trueCount = 0;
       for (Boolean b : this.onsetQueue) {
         if (b) trueCount++;
       }
       
       //System.out.println("True: " + trueCount + ", Size: " + this.onsetQueue.size());
       if (trueCount > (0.5f * this.onsetQueue.size())) {
         this.beatCount++; 
       }
       
       this.onsetQueue.offer(true);
     } else {
       this.onsetQueue.offer(false);
     }
     
     if (this.onsetQueue.size() == 6) {
       this.onsetQueue.poll();
     }
   }
   
 }
 
 
 public int getAverageBPM() {
  return this.averageBPM; 
 }
 
 public boolean isOnset() {
   return this.beat.isOnset(); 
 }
 
 
 
  
  
}
class FractalSpirograph {

  float angle = 0;
  
  Orbit sun;
  Orbit end;
  
  //PVector is random list of 2D and 3D vectors
  LinkedBlockingQueue<PVector> path;
  
  float maxTime = 100.0f; //seconds
  
  GCodeWriter writer;
  
  long startTime = 0;
  
  public FractalSpirograph(GCodeWriter writer) {
    this.writer = writer;
    
  }
  
  public float pixelsToMM(float pixels) {
    return pixels / 2.0f; 
  }
  
  public void start()  {
     path = new LinkedBlockingQueue<PVector> (200);
     sun = new Orbit(width / 2, height / 2, 100.0f, 1.0f / maxTime);
     Orbit next = sun;
     //for less circles, make i<2 or i<1
     for (int i = 0; i < 2; i++)  {
       next = next.addChild ();
     }
     end = next;
     startTime = System.currentTimeMillis();
  }
       
        
  public void update(float r, float g, float b, float bass, float mid, float treble) {
    background (70);
    
    Orbit next = sun;
    while (next != null) {
        next.update ();
        //next.show ();
        next = next.child;
      
      
      //computer guy doesn't have this
      sun.show ();
      
      sun.r = 60 + bass / 4;
      sun.child.r = mid / 2;
      sun.child.child.r = treble;
      
      sun.speed = mid * 4;
           
    
      //float r1 = 100;  
      //float x1 = 300;
      //float y1 = 300;
      
      //strokeWeight (2);
      //stroke (255);
      //noFill ();
      //ellipse (x1, y1, r1*2, r1*2);
      
      
      ////this collects the path points so that we can later plot it 
      path.offer(new PVector (end.x, end.y));
      this.writer.goToCoordinate(pixelsToMM(end.x - width / 2) / 2.5f, pixelsToMM(end.y - height / 2) / 2.5f, -0.5f);
      
      if (System.currentTimeMillis() - startTime > 30000) {
        this.writer.close();
        
        while(!this.writer.isClosed()) {
          try{
            Thread.sleep(2000);
          } catch( Exception e) {
             
          }
        }
        
        //System.exit(0);
        //return; 
      }
      
      if (path.remainingCapacity() == 0) {
        path.poll(); 
      }
      
      
      beginShape ();
      stroke(r,g,b);
      strokeWeight(3);
      for (PVector pos : path) {
        
        vertex(pos.x, pos.y);
        
        
      }
      endShape ();
    }
  }
}



class GCodeSender {
  
 final Serial serial;
 
 public float x, y, z = 0.0f;
 private final float feedRate = 800.0f;
 
 OutboxSender outboxSender;
  
 public GCodeSender(Serial serial) {
   this.serial = serial;
   this.outboxSender = new OutboxSender(serial);
 }
 
 public void start() {
   Thread outboxThread = new Thread(outboxSender);
   outboxThread.start();
   
   this.softReset();
   this.sleep(1);
   this.killAlarm();
   this.send("M3\n");
   this.setUnitsToMillis();
   this.sleep(2);
   this.penToHeight(0.0f);
   this.sleep(1);
   this.resetZero();
   this.sleep(3);
   this.goToCoordinate(0, 0, 0, this.feedRate);
   this.sleep(3);
 }
 
 public void setUnitsToMillis() {
   this.send("G21\n"); 
 }
 
 public void goToCoordinate(float x, float y, float z, float feedRate) {
   x = round(x); y = round(y); z = round(z);
   
   this.send("G01 X" + x + " Y" + y + " Z" + z + " F" + feedRate);
   this.x = x; this.y = y; this.z = z;
   this.newline();
 }
 
 public void goToCoordinate(float x, float y, float z) {
   x = round(x); y = round(y); z = round(z);
   
   this.send("G01 X" + x + " Y" + y + " Z" + z);
   this.x = x; this.y = y; this.z = z;
   this.newline();
 }
 
 public void goToCoordinate(float x, float y) {
   x = round(x); y = round(y);
   
   this.send("G01 X" + x + " Y" + y);
   this.x = x; this.y = y;
   this.newline();
 }
 
 public void offset(float x, float y, float z){
   x = round(x); y = round(y); z = round(z);
   
   this.send("G01 X" + x + " Y" + y + " Z" + z);
   this.x = this.x + x; this.y = this.y + y; this.z = this.z + z;
   this.newline();
 }
 
 public void offset(float x, float y){
   x = round(x); y = round(y);
   
   this.send("G01 X" + x + " Y" + y);
    this.x = this.x + x; this.y = this.y + y;
   this.newline();
 }
 
 public void liftPen() {
  this.send("G01 Z0.5 F" + feedRate + "\n");  
  this.z = 0.2f;
 }
 
 public void lowerPen() {
  this.send("G01 Z-0.5 F" + feedRate + "\n"); 
  this.z = -0.2f;
 }
 
 public void resetZero() {
    this.send("G10 P0 L20 X0 Y0 Z0\n");
    this.x = 0; this.y = 0; this.z = 0;
 }
 
 public void penToHeight(float z) {
    this.send("G01 Z" + z + " F" + feedRate + "\n");
    this.newline();
    this.z = z;
 }
 
 public void softReset() {
    this.serial.write(0x18); 
    this.z = 0.0f;
 }
 
 public void killAlarm() {
   this.serial.write("$X\n");
 }
 
 private void send(String str) {
   //this.serial.write(str); 
   this.outboxSender.add(str);
 }
 
 private void newline() {
   this.outboxSender.add("\n"); 
 }
 
 private float round(float num) {
   return new Float(Math.round((double)num * 100000d) / 100000d);
 }
 
 private void sleep(int sec) {
   try {
     Thread.sleep(1000 * sec);
   } catch(InterruptedException e) {
    
   }
 }
}



class GCodeWriter {
  
 public float x, y, z = 0.0f;
 private final float feedRate = 1000.0f;
 
 PrintWriter writer;
 GCodeWriterOutbox outbox;
  
 public GCodeWriter() {
   writer = createWriter("gcode2.ngc");
   outbox = new GCodeWriterOutbox(writer);
   
   Thread outboxThread = new Thread(outbox);
   outboxThread.start();
 }
 
 public void start() {
   this.send("%\n");
   this.send("(Header)\n");
   this.send("M3\n");
   this.send("(Header end.)\n");
   this.setUnitsToMillis();
   this.penToHeight(0.0f);
   this.resetZero();
   this.goToCoordinate(0, 0, 0, this.feedRate);
 }
 
 public void setUnitsToMillis() {
   this.send("G21\n"); 
 }
 
 public void goToCoordinate(float x, float y, float z, float feedRate) {
   x = round(x); y = round(y); z = round(z);
   
   this.send("G01 X" + x + " Y" + y + " Z" + z + " F" + feedRate);
   this.x = x; this.y = y; this.z = z;
   this.newline();
 }
 
 public void goToCoordinate(float x, float y, float z) {
   x = round(x); y = round(y); z = round(z);
   
   this.send("G01 X" + x + " Y" + y + " Z" + z);
   this.x = x; this.y = y; this.z = z;
   this.newline();
 }
 
 public void goToCoordinate(float x, float y) {
   x = round(x); y = round(y);
   
   this.send("G01 X" + x + " Y" + y);
   this.x = x; this.y = y;
   this.newline();
 }
 
 public void offset(float x, float y, float z){
   x = round(x); y = round(y); z = round(z);
   
   this.send("G01 X" + x + " Y" + y + " Z" + z);
   this.x = this.x + x; this.y = this.y + y; this.z = this.z + z;
   this.newline();
 }
 
 public void offset(float x, float y){
   x = round(x); y = round(y);
   
   this.send("G01 X" + x + " Y" + y);
    this.x = this.x + x; this.y = this.y + y;
   this.newline();
 }
 
 public void liftPen() {
  this.send("G01 Z0.5 F" + feedRate + "\n");  
  this.z = 0.2f;
 }
 
 public void lowerPen() {
  this.send("G01 Z-0.5 F" + feedRate + "\n"); 
  this.z = -0.2f;
 }
 
 public void resetZero() {
    this.send("G10 P0 L20 X0 Y0 Z0\n");
    this.x = 0; this.y = 0; this.z = 0;
 }
 
 public void penToHeight(float z) {
    this.send("G01 Z" + z + " F" + feedRate + "\n");
    this.newline();
    this.z = z;
 }
 
 private void send(String str) {
   //this.serial.write(str); 
   System.out.println("Writer sending " + str);
   this.outbox.add(str);
 }
 
 private void newline() {
   this.outbox.add("\n"); 
 }
 
 private float round(float num) {
   return new Float(Math.round((double)num * 100000d) / 100000d);
 }
 
 public void close() {
   this.send("(Footer)\n");
   this.send("M5\n");
   this.send("G00 X0 Y0\n");
   this.send("M2\n");
   this.send("(End)\n");
   this.send("%\n");
   
   this.outbox.close(); 
 }
 
 public boolean isClosed() {
  return this.outbox.isClosed(); 
 }
}
class GCodeWriterOutbox implements Runnable{
  
  PrintWriter writer;
  LinkedBlockingQueue<String> outbox;
  
  int newline = 10;
  
  boolean stopped = false;
  boolean closed = false;
  
  public GCodeWriterOutbox(PrintWriter writer) {
   this.writer = writer;
   this.outbox = new LinkedBlockingQueue<String>();
  }
  
  
  @Override 
  public void run() {
    while (!stopped) {
       if (outbox.size() > 0) {
         
         String toSend = outbox.poll();
         System.out.println("Outbox size: " + outbox.size());
         
         this.writer.print(toSend);
       }
       //System.out.println("Outbox empty!");
     } 
     
     System.out.println("Writer Stopped!");
     
     this.writer.close();
     this.closed = true;
  }
  
  public LinkedBlockingQueue<String> getOutbox() {
    return this.outbox; 
  }
  
  public void add(String str) {
    //System.out.println("Adding to outbox: " + str);
    this.outbox.offer(str);
  }
  
  public void close() {
    this.stopped = true;
  }
  
  public boolean isClosed() {
    return this.closed; 
  }
}
class Orbit {
  float x;
  float y;
  float r;
  Orbit parent;
  Orbit child;
  float speed;
  float angle;
  
  long startTime = 0;
  
  Orbit (float x_, float y_, float r_, float s) {
    this(x_, y_, r_, s, null);
  }
  
  Orbit(float x_, float y_, float r_, float s, Orbit p) {
    x = x_;
    y = y_;
    r = r_;
    speed = s ;
    parent = p;
    child = null;
    angle = 0;
    startTime = System.currentTimeMillis();
  }
    
  public Orbit addChild () {
      //to make circles smaller make r * smaller value
      float newr = r / 3;
      float newx = x + r + newr;
      float newy = y;
      child = new Orbit(newx, newy, newr, -30*speed, this);
      return child;
  }
  
  public void update () {
    if (parent != null) {
      long timeDelta = System.currentTimeMillis() - startTime;
      float timeDeltaSec = (float) timeDelta / 1000.0f;
      
      angle =  speed * timeDeltaSec; 
      
      float rsum = r + parent.r;
      x = parent.x + rsum * cos(angle);
      y = parent.y + rsum * sin(angle);
    }
      //ellipse (x2, y2, r2*2, r2*2);
  }
  
  public float getAngle() {
    return this.angle;
  }
  
  public void show () {
    stroke (255);
    strokeWeight (1);
    noFill();
    ellipse (x, y, r*2, r*2);
  }
}
class OutboxSender implements Runnable{
  
  Serial serial;
  LinkedBlockingQueue<String> outbox;
  
  int newline = 10;
  
  public OutboxSender(Serial serial) {
   this.serial = serial; 
   this.outbox = new LinkedBlockingQueue<String>();
    
  }
  
  
  @Override 
  public void run() {
    while (true) {
       if (outbox.size() > 0) {
         
         String toSend = outbox.poll();
         System.out.println("Outbox size: " + outbox.size());
         if (!toSend.equals("\n")) System.out.println("Sending " + toSend);
         
         this.serial.write(toSend);
         String data = this.serial.readStringUntil(10);
         
         if (data != null) {
           System.out.println("String data received: " + data);
           
           while (!data.contains("ok")) {
             data = this.serial.readStringUntil(10);
             
             if (data == null) break;
             
             System.out.println("String data received: " + data);
           }
         }
         
       }
       try { 
         Thread.sleep(100); 
       } catch (Exception e) {
         
       }
       
    }
  }
  
  public LinkedBlockingQueue<String> getOutbox() {
    return this.outbox; 
  }
  
  public void add(String str) {
    //System.out.println("Adding to outbox: " + str);
    this.outbox.offer(str);
  }
}
class Spot{
  
 float x, y, r, g, b;
  
 public Spot(float x, float y, float r, float g, float b) {
   this.x = x; this.y = y; this.r = r; this.g = g; this.b = b;
 }
 
 public void render() {
   stroke(r, g, b, 40);
   vertex(x, y);
 }
}
  public void settings() {  size(1000, 750); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "audioVisualizer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}

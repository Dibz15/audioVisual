import ddf.minim.*;
import ddf.minim.analysis.*;
import java.io.*;
import processing.serial.*;

Minim minim;
AudioPlayer song;
FFT fft;

BeatDetection beat;

float specLow = 0.03; // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.20; // 20%

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


Serial serial;
GCodeSender sender;
GCodeWriter writer;

final boolean SEND_CODE = true;

FractalSpirograph fractal;

ArrayList<Spot> spots;

void setup() {
  minim = new Minim(this);

  selectInput("Select a file to process:", "fileSelected");
  //Load song
  size(1000, 750);
  //fullScreen(P2D);
  //serial = new Serial(this, "/dev/ttyUSB0", 115200);
  serial = null;
  sender = new GCodeSender(serial);
  writer = new GCodeWriter();
  
  fractal = new FractalSpirograph(writer);
  fractal.start();
  
  spots = new ArrayList<Spot>(1000);
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    System.exit(0);
  } else {
    println("User selected " + selection.getAbsolutePath());
    setupSong(selection);
  }
}

void setupSong(File selection) {
  song = minim.loadFile(selection.getAbsolutePath());
  fft = new FFT(song.bufferSize(), song.sampleRate());
  //sender.start();
  writer.start();
  song.play(0);
  beat = new BeatDetection(song);
}

void draw() {
  if (backgroundCount % backgroundRate == 0) {
    background(215);
    backgroundCount = 1;
  }
  backgroundCount++;
  
  if (fft != null && song != null && beat != null) {
    beat.update();
    //System.out.println(beat.getAverageBPM());
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
    scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
  
    //linearFFTDisplay();
    //simpleCircularFFTDisplay();
    //slowCircularFFTDisplay();
    //slowCircularFFTDisplay2();
    //slowCircularFFTDisplay3();
    fractal.update(scoreLow / 5, scoreMid / 5, scoreHi / 5, scoreLow / 10, scoreMid / 8, scoreHi / 6);
    simpleBeatDetect();
    
    
    for (Spot spot : spots) {
      beginShape ();
      //strokeWeight(2);
      spot.render();
      endShape ();
    }
    
    
  } else {
    background(255);
    startTime = System.currentTimeMillis(); 
  }
}


float startAngle = 0;

void slowCircularFFTDisplay() {
  int maxTime = 30; //Seconds
  int numPoints = 2 * maxTime; //Data points for whole circle. Default is 2 points per second
  
  long timeDelta = System.currentTimeMillis() - lastTime;
  float timeDeltaSec = ((float) timeDelta) / 1000.0f;
  
  float angle = 2 * (float) Math.PI / numPoints * timeDeltaSec;
  
  if (angle >= 2 * (float) Math.PI) {
    this.writer.close();
    
    while(!this.writer.isClosed()) {
      try{
        Thread.sleep(2000);
      } catch( Exception e) {
         
      }
    }
    
    //System.exit(0);
    return; 
  }
  
  float centerX = width / 2, centerY = height / 2;
  float offsetCenterX = scoreGlobal / 12 * cos(angle);
  float offsetCenterY = scoreGlobal / 12 * sin(angle); 
  strokeWeight(4);
  stroke(scoreLow / 5, scoreMid / 5, scoreHi / 5);
  //point(centerX + offsetCenterX, centerY + offsetCenterY);
  
  float upperX = width * 0.80, upperY = height * 0.20, lowerX = width * 0.20, lowerY = height * 0.80;
  spots.add(new Spot(upperX + offsetCenterX, upperY + offsetCenterY, scoreLow / 5, scoreMid / 5, scoreHi / 5));
  spots.add(new Spot(lowerX + offsetCenterX, lowerY + offsetCenterY, scoreLow / 5, scoreMid / 5, scoreHi / 5));
  
  writer.goToCoordinate(pixelsToMM(offsetCenterX), pixelsToMM(offsetCenterY), -0.5);
}

float tempMax = 0, tempMin = 100000000.0f;

void slowCircularFFTDisplay3() {
  
  int maxTime = 30; //Seconds
  int numPoints = (int)(1.5f * maxTime); //Data points for whole circle. Default is 2 points per second
  
  long timeDelta = System.currentTimeMillis() - lastTime;
  float timeDeltaSec = ((float) timeDelta) / 1000.0f;
  
  long startTimeDelta = System.currentTimeMillis() - startTime;
  float startTimeDeltaSec = ((float) startTimeDelta) / 1000.0f;
  
  long lastTimeDelta = System.currentTimeMillis() - lastTime;
  float lastTimeDeltaSec = ((float) lastTimeDelta) / 1000.0f;
  
  float timePerDot = ((float) maxTime) / ((float) numPoints);
  
  float angle = 2 * (float) Math.PI / numPoints * startTimeDeltaSec;
  
  if (angle >= 2 * (float) Math.PI) {
    return; 
  }
  
  if(lastTimeDeltaSec >=  timePerDot) {
    //float angle = 2 * (float) Math.PI / numPoints * startTimeDeltaSec;
    float centerX = width / 2, centerY = height / 2;
    float offsetCenterX = tempMax * cos(angle);
    float offsetCenterY = tempMax * sin(angle); 
    
    float offsetLowerX = tempMin * cos(angle);
    float offsetLowerY = tempMin * sin(angle);
    
    strokeWeight(4);
    stroke(scoreLow / 5, scoreMid / 5, scoreHi / 5);
    
   // line(centerX + offsetLowerX, centerY + offsetLowerY, centerX + offsetCenterX, centerY + offsetCenterY);
    
    if (SEND_CODE && offsetLowerX < 10 && offsetLowerY < 10) {
      sender.goToCoordinate(pixelsToMM(offsetCenterX), pixelsToMM(offsetCenterY), -0.5);
      //sender.lowerPen();
      sender.goToCoordinate(pixelsToMM(offsetLowerX), pixelsToMM(offsetLowerY));
      sender.liftPen();
    }
    lastX = centerX + offsetCenterX; lastY = centerY + offsetCenterY;
    //lastRed = scoreLow / 5; lastGreen = scoreMid / 5; lastBlue = scoreHi / 5;
    lastTime = System.currentTimeMillis();
    
    tempMax = 0; tempMin = 100000000.0f;
  }
  
  tempMax = max(tempMax, scoreGlobal / 8);
  tempMin = min(tempMin, scoreGlobal / 8);
  
}

float lastX = 0, lastY = 0;

void slowCircularFFTDisplay2() {
  
  int maxTime = 30; //Seconds
  int numPoints = 2 * maxTime; //Data points for whole circle. Default is 2 points per second
  
  long startTimeDelta = System.currentTimeMillis() - startTime;
  float startTimeDeltaSec = ((float) startTimeDelta) / 1000.0f;
  
  long lastTimeDelta = System.currentTimeMillis() - lastTime;
  float lastTimeDeltaSec = ((float) lastTimeDelta) / 1000.0f;
  
  float timePerDot = ((float) maxTime) / ((float) numPoints);
  
  if(lastTimeDeltaSec >=  timePerDot) {
    float angle = 2 * (float) Math.PI / numPoints * startTimeDeltaSec;
    
    float centerX = width / 2, centerY = height / 2;
    float offsetCenterX = scoreGlobal / 8 * cos(angle);
    float offsetCenterY = scoreGlobal / 8 * sin(angle); 
    strokeWeight(4);
    stroke(scoreLow / 5, scoreMid / 5, scoreHi / 5);
    
    line(lastX, lastY, centerX + offsetCenterX, centerY + offsetCenterY);
    
    point(centerX + offsetCenterX, centerY + offsetCenterY);
    
    lastX = centerX + offsetCenterX; lastY = centerY + offsetCenterY;
    //lastRed = scoreLow / 5; lastGreen = scoreMid / 5; lastBlue = scoreHi / 5;
    lastTime = System.currentTimeMillis();
  }
}

void linearFFTDisplay() {
   for (int i = 0; i < fft.specSize(); i++) {
      //draw the line for frequency band i, scaling it by 4
      strokeWeight(2);
      line(i*2 + 25, height, i*2 + 25, height - fft.getBand(i) * 4);
    }
}

void simpleCircularFFTDisplay() {
  for (int i = 0; i < fft.specSize()*specHi; i++) {
    float angle = 2 * (float) Math.PI / fft.specSize() / specHi * i;
    float centerX = width / 2, centerY = height / 2;
    float offsetCenterX = scoreGlobal / 8 * cos(angle);
    float offsetCenterY = scoreGlobal / 8 * sin(angle); 
    
    float band = fft.getBand(i);
    if (i < fft.specSize() * specLow) {
      band = 0.66 * band;
    } else if (i > fft.specSize() * specLow && i < fft.specSize() * specMid) {
      band = 0.8 * band;
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


float pixelsToMM(float pixels) {
  return pixels / 2.0f; 
}

void simpleBeatDetect() {
  if (beat.isOnset()) {
    //ellipse(width / 2, height / 2, 50, 50);
    
  }
}

import ddf.minim.*;
import ddf.minim.analysis.*;
import java.io.*;
import processing.serial.*;
import java.util.*;

Minim minim;
AudioPlayer song;
AudioMetaData meta;
FFT fft;

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

ArrayList<Spot> spots;
List<File> songFiles;
int songIndex = 0;

boolean isPaused = true;

void setup() {
  minim = new Minim(this);
  selectFolder("Select a file to process:", "folderSelected");
  //Load song
  size(1000, 750);
  spots = new ArrayList<Spot>(1000);
  surface.setResizable(true);
}

void folderSelected(File selection) {
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

String getFileExtension(File file) {
  String extension = "";

  int i = file.getPath().lastIndexOf('.');
  if (i > 0) {
      extension = file.getPath().substring(i+1);
  } 
  
  return extension;
}

void setupSong(File selection) {
  try {
    isPaused = true;
    song = minim.loadFile(selection.getAbsolutePath());
    meta = song.getMetaData();
    fft = new FFT(song.bufferSize(), song.sampleRate());
    System.out.println("Playing song " + meta.title());
    song.play();
    isPaused = false;
  } catch (NullPointerException e) {
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

void draw() {
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
    scoreGlobal = 0.66*scoreLow + 0.8*scoreMid + 1*scoreHi;
  
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
    
    if (!song.isPlaying() && !isPaused) {
      songIndex++;
      if (songIndex == songFiles.size()) {
        songIndex = 0; 
      }
      song.pause();
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
void keyPressed() {
  if (keyCode == RIGHT) {
    nextSong = true;
  }else if (keyCode == LEFT) {
    prevSong = true;
  }
}


float startAngle = 0;

void slowCircularFFTDisplay() {
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
  
  float upperX = width * 0.80, upperY = height * 0.20, lowerX = width * 0.20, lowerY = height * 0.80;
  spots.add(new Spot(upperX + offsetCenterX, upperY + offsetCenterY, scoreLow / 5, scoreMid / 5, scoreHi / 5));
  spots.add(new Spot(lowerX + offsetCenterX, lowerY + offsetCenterY, scoreLow / 5, scoreMid / 5, scoreHi / 5));
}

float tempMax = 0, tempMin = 100000000.0f;


float lastX = 0, lastY = 0;


void simpleCircularFFTDisplay2() {
  float timeOffset = System.currentTimeMillis() - startTime;
  
  for (int i = 0; i < fft.specSize()*specHi; i++) {
    float angle = 2 * (float) Math.PI / fft.specSize() / specHi * i + (timeOffset / 5000.0f);
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

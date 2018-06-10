import java.util.concurrent.LinkedBlockingQueue;

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
     int val = int(60.0f / ((float) sampleTime / 1000.0f)* (float) beatCount);
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
       if (trueCount > (0.5 * this.onsetQueue.size())) {
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

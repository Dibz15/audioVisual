


class GCodeSender {
  
 final Serial serial;
 
 public float x, y, z = 0.0;
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
  this.z = 0.2;
 }
 
 public void lowerPen() {
  this.send("G01 Z-0.5 F" + feedRate + "\n"); 
  this.z = -0.2;
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

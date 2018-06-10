


class GCodeWriter {
  
 public float x, y, z = 0.0;
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

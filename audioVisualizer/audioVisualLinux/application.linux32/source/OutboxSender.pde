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

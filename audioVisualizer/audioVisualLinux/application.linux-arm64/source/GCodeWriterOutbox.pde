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

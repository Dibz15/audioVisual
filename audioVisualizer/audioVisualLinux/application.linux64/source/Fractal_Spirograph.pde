class FractalSpirograph {

  float angle = 0;
  
  Orbit sun;
  Orbit end;
  
  //PVector is random list of 2D and 3D vectors
  LinkedBlockingQueue<PVector> path;
  
  float maxTime = 100.0; //seconds
  
  GCodeWriter writer;
  
  long startTime = 0;
  
  public FractalSpirograph(GCodeWriter writer) {
    this.writer = writer;
    
  }
  
  float pixelsToMM(float pixels) {
    return pixels / 2.0f; 
  }
  
  void start()  {
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
       
        
  void update(float r, float g, float b, float bass, float mid, float treble) {
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
      this.writer.goToCoordinate(pixelsToMM(end.x - width / 2) / 2.5, pixelsToMM(end.y - height / 2) / 2.5, -0.5);
      
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

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
    
  Orbit addChild () {
      //to make circles smaller make r * smaller value
      float newr = r / 3;
      float newx = x + r + newr;
      float newy = y;
      child = new Orbit(newx, newy, newr, -30*speed, this);
      return child;
  }
  
  void update () {
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
  
  void show () {
    stroke (255);
    strokeWeight (1);
    noFill();
    ellipse (x, y, r*2, r*2);
  }
}

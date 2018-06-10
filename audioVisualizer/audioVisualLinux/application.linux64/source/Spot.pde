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

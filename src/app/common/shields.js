const brickWidth = 10, brickHeight = 5;

class Brick{
  constructor(x,y){
    this.x = x||0;
    this.y = y||0;
    this.width = brickWidth;
    this.height = brickHeight;
  }
}
class Stack{
  constructor(x,y){
    this.bricks = [];
    this.brickHeight = 10;
    this.x = x;
    this.y = y;
    for(let i=0,brick,cy=y;i<this.brickHeight;i++){
      brick = new Brick(this.x,cy);
      cy += brickHeight;
      this.bricks.push(brick);
    } //end for
  }
}
class Shield{
  constructor(xPercentage,y){
    this.stacks = [];
    this.stackWidth = 12;
    this.width = brickWidth*this.stackWidth;
    this.arcRadius = 30;
    this.x = xPercentage*v.w-this.width/2;
    this.y = y;
    for(let i=0,stack,cx=this.x,cy;i<=this.stackWidth;i++){
      cy = this.y-this.arcRadius*Math.sin(Math.PI/this.width*brickWidth*i);
      stack = new Stack(cx,cy);
      cx += brickWidth;
      this.stacks.push(stack);
    } //end for
  }
}

let shields = [
  new Shield(1/4,v.h-130),
  new Shield(1/2,v.h-130),
  new Shield(3/4,v.h-130)
];

export {shields};

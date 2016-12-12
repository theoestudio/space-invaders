class Brick{
  constructor(x,y){
    this.x = x||0;
    this.y = y||0;
    this.width = 10;
    this.height = 5;
  }
}
class Stack{
  constructor(x,y,layers){
    this.bricks = [];
    this.layers = layers || 2;
    this.width = 0;
    this.height = 0;
    this.x = x;
    this.y = y;
    for(let i=0,brick,cy=y;i<this.layers;i++){
      brick = new Brick(this.x,cy);
      cy += brick.height;
      this.width = brick.width;
      this.height += brick.height;
      this.bricks.push(brick);
    } //end for
  }
}
class Shield{
  constructor(x,y,depth){
    this.stacks = [];
    this.depth = depth || 10;
    this.width = 0;
    this.height = 0;
    this.x = x;
    this.y = y;
    for(let i=0,stack,cx=x;i<this.depth;i++){
      stack = new Stack(cx,this.y,10);
      cx += stack.width;
      this.width += stack.width;
      this.height += stack.height;
      this.stacks.push(stack);
    } //end for
  }
}

let shields = [
  new Shield(v.w/4,v.h-200),
  new Shield(v.w/4*2,v.h-200),
  new Shield(v.w/4*3,v.h-200)
];

export {shields};

import {invaders} from './invaders';

let missiles = [];

class Missile{
  constructor(){
    let invader = invaders.getRandom(),
        sx = invader.x+invader.imageWidth/2,
        sy = invader.y+invader.imageHeight;

    this.id = missiles.length;
    this.x = this.originX = this.startX = this.terminalX = this.endX = sx;
    this.y = this.originY = this.startY = sy;
    this.endY = this.terminalY = this.y+v.h;
    this.tweenCurrent = 0;
    this.tweenDuration = 200;
    this.tweenType = 'linear';
    this.color = '#ffa';
    this.size = 3;
    this.onEnd = function onEnd(particle){
      this.collection.splice(particle.id,1);
      this.collection.forEach((p,i)=> p.id=i); //re-index array
    };
  }
}

missiles.startGeneration = function generateMissile(){
  this.push(new Missile);
  setTimeout(()=>generateMissile.call(this),r(100,500,true));
};

export {missiles};

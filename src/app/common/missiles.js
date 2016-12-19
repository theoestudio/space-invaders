import {invaders} from './invaders';

let missiles = [];

class Missile{
  constructor(player){
    let origin = player?player:invaders.getRandom(),
        sx = origin.x+origin.imageWidth/2,
        sy = origin.y+(player?0:origin.imageHeight);

    console.log('player',player,sx,sy);
    this.id = missiles.length;
    this.x = this.originX = this.startX = this.terminalX = this.endX = sx;
    this.y = this.originY = this.startY = sy;
    if(player){
      this.endY = this.terminalY = this.y-v.h;
    }else{
      this.endY = this.terminalY = this.y+v.h;
    } //end if
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

missiles.shootFrom = function shootFrom(player){
  this.push(new Missile(player));
};

export {missiles};

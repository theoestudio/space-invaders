import {generateInvader} from './generateInvader';

let types = 4,
    colors = ['#ee1f30','#fab630','#43af52','#2dbfd4'], //length = types
    images = Array.from(new Array(types),()=> generateInvader()),
    invaders = [];

class Invader{
  constructor(id,type,dx,dy){
    this.id = id;
    this.x = this.originX = this.startX = r(1, v.w, true);
    this.y = this.originY = this.startY = 15;
    this.terminalX = this.endX = dx;
    this.terminalY = this.endY = dy;
    this.tweenCurrent = 0;
    this.tweenDuration = 100;
    this.tweenType = 'ease-out-circular';
    this.size = 1;
    this.color = colors[type];
    this.image = images[type];
    this.windX = ()=> r(0.02)-0.01;
    this.windY = ()=> r(0.02)-0.01;
    this.imageWidth = 40;
    this.imageHeight = 40;
    this.onEnd = function invaderFinished(invader){
      this.status--; //decrement the number left to finish
      if(this.status===0) this.finished = true;
    };
  }
}

for(let y=0;y<4;y++){
  for(let x=0;x<10;x++){
    let dx = Math.floor(x*v.w/3*2/10+v.w/6),
        dy = Math.floor(y*v.h/3*2/10+v.h/10);

    invaders.push(new Invader(invaders.length,(invaders.length/10)|0,dx,dy));
  } //end for
} //end for
invaders.getRandom = ()=> invaders[r(0,invaders.length,true)];
export {invaders};

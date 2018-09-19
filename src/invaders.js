import {generateInvader} from './generateInvader';

const types = 4,
      colors = ['#ee1f30','#fab630','#43af52','#2dbfd4'], //length = types
      images = Array.from(new Array(types),()=> generateInvader()),
      invaders = [];

class Invader{
  constructor(easel,id,type,dx,dy){
    this.easel = easel;
    this.id = id;
    this.x = this.originX = this.startX = r(1, easel.viewport.w, true);
    this.y = this.originY = this.startY = 15;
    this.terminalX = this.endX = dx;
    this.terminalY = this.endY = dy;
    this.tweenCurrent = 0;
    this.tweenDuration = 100;
    this.tweenType = 'ease-out-circular';
    this.color = colors[type];
    this.image = images[type];
    if(easel.viewport.w>800){
      this.imageWidth = 40;
      this.imageHeight = 40;
    }else{
      this.imageWidth = 20;
      this.imageHeight = 20;
    } //end if
    this.onEnd = function invaderFinished(){
      this.status--; //decrement the number left to finish
      if(this.status===0) this.finished = true;
    };
  }
}

invaders.startGeneration = function generateInvader(easel){
  for(let y=0;y<4;y++){
    for(let x=0;x<10;x++){
      const dx = Math.floor(x*easel.viewport.w/3*2/10+easel.viewport.w/6),
            dy = Math.floor(y*easel.viewport.h/3*2/10+easel.viewport.h/10);

      invaders.push(new Invader(easel,invaders.length,(invaders.length/10)|0,dx,dy));
    } //end for
  } //end for
};

invaders.getRandom = ()=> invaders[r(0,invaders.length,true)];

export {invaders};

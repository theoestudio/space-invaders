import {generateInvader} from './generateInvader';
import {missiles} from './missiles';

class Player{
  constructor(){
    this.x = this.originX = this.startX = v.w/2;
    this.y = this.originY = this.startY = v.h-50;
    this.terminalX = this.endX = this.x;
    this.terminalY = this.endY = this.y;
    this.tweenCurrent = 50;
    this.tweenDuration = 50;
    this.tweenType = 'ease-out-circular';
    this.color = '#afa';
    this.image = generateInvader();
    this.imageWidth = 40;
    this.imageHeight = 40;
    this.score = 0;
  }
  moveRight(){
    this.startX = this.originX = this.x;
    this.terminalX = this.endX+=50;
    this.tweenCurrent = 0;
  }
  moveLeft(){
    this.startX = this.originX = this.x;
    this.terminalX = this.endX-=50;
    this.tweenCurrent = 0;
  }
}

let player = new Player();

document.addEventListener('keydown', e=>{
  if(e.code==='ArrowRight'){
    player.moveRight();
  }else if(e.code==='ArrowLeft'){
    player.moveLeft();
  }else if(e.code==='Space'){
    missiles.shootFrom(player);
  } //end if
});

export {player};

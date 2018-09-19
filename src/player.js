import {generateInvader} from './generateInvader';

export class Player{
  constructor(easel){
    this.easel = easel;
    this.x = this.originX = this.startX = this.easel.viewport.w/2;
    this.y = this.originY = this.startY = this.easel.viewport.h-50;
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

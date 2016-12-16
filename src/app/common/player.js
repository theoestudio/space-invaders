import {generateInvader} from './generateInvader';

class Player{
  constructor(){
    this.image = generateInvader();
    this.color = '#afa';
    this.x = v.w/2;
    this.width = 40;
    this.height = 40;
    this.y = v.h-50;
  }
}

let player = new Player();

document.addEventListener('keydown', e=>{
  if(e.code==='ArrowRight'){
    player.x+=10;
  }else if(e.code==='ArrowLeft'){
    player.x-=10;
  } //end if
});

export {player};

import {dayCycle} from '../background';
import {player} from '../player';

export function lost(){
  // Draw background
  dayCycle.drawNext(true);

  // Draw a ground
  ctx.fillStyle='rgb(10,80,10)';
  ctx.fillRect(0,v.h-10,v.w,10);

  // Draw main text
  ctx.fillStyle='#F99';
  ctx.textAlign='center';
  ctx.textBaseline='middle';
  ctx.font = '48px Orbitron';
  ctx.fillText('GAME OVER',v.w/2,v.h/2);

  // Draw play again text
  ctx.fillStyle = '#ff9';
  ctx.font = '18px Orbitron';
  if(v.w<800){
    ctx.fillText('[TOUCH SCREEN TO PLAY AGAIN]',v.w/2,v.h/4*3);
  }else{
    ctx.fillText('[CLICK SCREEN TO PLAY AGAIN]',v.w/2,v.h/4*3);
  } //end if

  // Draw score
  let bgColor = ctx.getImageData(15,15,1,1).data,
      average = (bgColor[0]+bgColor[1]+bgColor[2])/3/255;

  ctx.textAlign = 'left';
  ctx.font = '24px Orbitron';
  ctx.textBaseline = 'top';
  if(average>0.5){
    ctx.fillStyle='#000';
  }else{
    ctx.fillStyle='#fff';
  } //end if
  ctx.fillText(`SCORE: ${player.score}`,15,15);
} //end lost()

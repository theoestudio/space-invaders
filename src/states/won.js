/* eslint-disable no-invalid-this */
export function won(){
  const {dayCycle,easel,player} = this,
        {ctx,viewport} = easel;

  // Draw background
  dayCycle.drawNext(true);

  // Draw a ground
  ctx.fillStyle='rgb(10,80,10)';
  ctx.fillRect(0,viewport.h-10,viewport.w,10);

  // Draw main text
  ctx.fillStyle='#9F9';
  ctx.textAlign='center';
  ctx.textBaseline='middle';
  ctx.font = '48px Orbitron';
  ctx.fillText('WINNER!',viewport.w/2,viewport.h/2);

  // Draw score
  const bgColor = ctx.getImageData(15,15,1,1).data,
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
  gtag('event', 'end', {'result': 'win'});
} //end won()

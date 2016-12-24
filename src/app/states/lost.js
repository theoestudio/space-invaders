export function lost(){
  ctx.fillStyle='#F99';
  ctx.textAlign='center';
  ctx.textBaseline='middle';
  ctx.font = '48px Orbitron';
  ctx.fillText('GAME OVER',v.w/2,v.h/2);
} //end lost()

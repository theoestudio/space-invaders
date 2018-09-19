export function initial(){
  console.log('initial state',this);
  // Draw background
  dayCycle.drawNext(true);

  // Draw a ground
  ctx.fillStyle='rgb(10,80,10)';
  ctx.fillRect(0,v.h-10,v.w,10);

  // Draw score
  ctx.textAlign = 'left';
  ctx.font = '24px Orbitron';
  ctx.textBaseline = 'top';
  ctx.fillStyle = '#000';
  ctx.fillText('STARTING GAME...',15,15);

  // Draw shields
  ctx.fillStyle='#2dbfd4';
  shields.forEach(shield=>{
    shield.stacks.forEach(stack=>{
      stack.bricks.forEach(b=> ctx.fillRect(b.x,b.y,b.width,b.height));
    });
  });
} //end initial()

/* eslint-disable no-invalid-this */
export function initial () {
  const { dayCycle, easel, shields } = this;
  const { ctx, viewport } = easel;

  // Draw background
  dayCycle.drawNext(true);

  // Draw a ground
  ctx.fillStyle = 'rgb(10,80,10)';
  ctx.fillRect(0, viewport.h - 10, viewport.w, 10);

  // Draw score
  ctx.textAlign = 'left';
  ctx.font = '24px Orbitron';
  ctx.textBaseline = 'top';
  ctx.fillStyle = '#000';
  ctx.fillText('STARTING GAME...', 15, 15);

  // Draw shields
  ctx.fillStyle = '#2dbfd4';
  shields.forEach(shield => {
    shield.stacks.forEach(stack => {
      stack.bricks.forEach(b => ctx.fillRect(b.x, b.y, b.width, b.height));
    });
  });
} // end initial()

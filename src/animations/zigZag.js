/* eslint-disable no-invalid-this */
export function zigZag () {
  const zigZag = new this.Ion(this.easel);
  const { easel, invaders } = this;
  const { viewport } = easel;

  // eslint-disable-next-line array-callback-return
  invaders.list.map(invader => {
    invader.x = invader.startX = invader.originX = invader.endX;
    invader.y = invader.startY = invader.originY = invader.endY;
    invader.endX = invader.terminalX = invader.terminalX - (viewport.w / 6) | 0;
    invader.tweenCurrent = 0;
    invader.tweenDuration = 100; // 400
    invader.tweenType = 'ease-in-out-cubic';
    invader.state = 'left';
    invader.onEnd = function invaderFinished (invader) {
      invader.x = invader.startX = invader.originX = invader.endX;
      invader.y = invader.startY = invader.originY = invader.endY;
      if (invader.state === 'left') {
        invader.state = 'down-left';
        invader.endY = invader.terminalY = invader.terminalY + invader.imageHeight;
        invader.tweenDuration = Math.floor(invader.tweenDuration / 3);
        invader.tweenType = 'ease-out-cubic';
      } else if (invader.state === 'down-left') {
        invader.state = 'right';
        invader.endX = invader.terminalX = invader.terminalX + (viewport.w / 6 * 2) | 0;
        invader.tweenDuration = Math.floor(invader.tweenDuration * 3) - 50;
        invader.tweenType = 'ease-in-out-cubic';
      } else if (invader.state === 'right') {
        invader.state = 'down-right';
        invader.endY = invader.terminalY = invader.terminalY + invader.imageHeight;
        invader.tweenDuration = Math.floor(invader.tweenDuration / 3);
        invader.tweenType = 'ease-out-cubic';
      } else if (invader.state === 'down-right') {
        invader.state = 'left';
        invader.endX = invader.terminalX = invader.terminalX - (viewport.w / 6 * 2) | 0;
        invader.tweenDuration = Math.floor(invader.tweenDuration * 3) - 50;
        invader.tweenType = 'ease-in-out-cubic';
      } // end if
      if (invader.tweenDuration < 50) invader.tweenDuration = 50;
      invader.tweenCurrent = 0;
    };
  });
  zigZag.states = ['started'];
  zigZag.collection = invaders.list;
  return zigZag;
}

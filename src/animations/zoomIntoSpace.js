/* eslint-disable no-invalid-this */
export function zoomIntoSpace (options) {
  const zoomIntoSpace = new this.Ion(this.easel);
  const { onFinished } = options;

  zoomIntoSpace.states = ['initial'];
  zoomIntoSpace.status = this.invaders.list.length;
  zoomIntoSpace.onParticleEnd = () => {
    zoomIntoSpace.status--;
    if (!zoomIntoSpace.status) zoomIntoSpace.finished = true;
  };
  zoomIntoSpace.collection = this.invaders.list.map(invader => {
    invader.onEnd = zoomIntoSpace.onParticleEnd;
    return invader;
  });
  zoomIntoSpace.onFinished = onFinished;
  return zoomIntoSpace;
} // end zoomIntoSpace()

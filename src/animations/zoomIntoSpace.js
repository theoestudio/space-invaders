export function zoomIntoSpace(){
  console.log('zoom into space animation',this);
  const zoomIntoSpace = new Ion();

  zoomIntoSpace.states = ['initial'];
  zoomIntoSpace.status = invaders.length;
  zoomIntoSpace.collection = invaders;
  zoomIntoSpace.onFinished = callback;
  return zoomIntoSpace;
} //end zoomIntoSpace()

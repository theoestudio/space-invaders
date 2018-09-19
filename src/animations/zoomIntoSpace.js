export function zoomIntoSpace(){
  const zoomIntoSpace = new this.Ion(this.easel);

  zoomIntoSpace.states = ['initial'];
  zoomIntoSpace.status = this.invaders.list.length;
  zoomIntoSpace.collection = this.invaders.list;
  return zoomIntoSpace;
} //end zoomIntoSpace()

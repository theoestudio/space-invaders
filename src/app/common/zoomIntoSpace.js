import {Ion} from '../vendor/ion';
import {invaders} from './invaders';

export function zoomIntoSpace(){
  let zoomIntoSpace = new Ion(invaders.length);

  // Declare and initialize the scene
  zoomIntoSpace.collection = invaders;
  zoomIntoSpace.onEnd = (particle)=>{
    particle.startX = particle.endX;
    particle.startY = particle.endY;
    particle.tweenDuration = Infinity;
  };
  return zoomIntoSpace;
} //end zoomIntoSpace()

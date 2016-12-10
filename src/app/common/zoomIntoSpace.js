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
  zoomIntoSpace.clear = ()=>{
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, v.w, v.h);
    ctx.font = '18px Courier New';
    ctx.fillStyle = 'rgb(255,255,0)';
    ctx.fillText('space invaders, yay!', 5, v.h - 5);
  };
  return zoomIntoSpace;
} //end zoomIntoSpace()

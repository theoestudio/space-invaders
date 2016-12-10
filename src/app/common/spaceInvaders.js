import {zoomIntoSpace} from './zoomIntoSpace';
import {IonCloud} from '../vendor/ionCloud';

export function spaceInvaders() {
  let scene = new IonCloud();

  scene.make(zoomIntoSpace);
  scene.draw();
  scene.clearScene=()=>{
    // Clear screen
    ctx.fillStyle='#000';
    ctx.fillRect(0,0,v.w,v.h);
  };
} //end app()

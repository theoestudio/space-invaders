import {IonCloud} from 'ion-cloud';
import * as animations from './animations/';
import * as states from './states/';
import {missiles} from './missiles';

let scene = new IonCloud();

export {scene};

export function spaceInvaders(){
  scene.animate(animations.playerMovement);
  scene.animate(animations.zoomIntoSpace,()=>{
    scene.state = 'started';
    scene.animate(animations.zigZag);
    scene.animate(animations.missileAttacks);
    missiles.startGeneration();
  });
  scene.makeState('initial',states.initial);
  scene.makeState('started',states.started);
  scene.makeState('won',states.won);
  scene.makeState('lost',states.lost);
  scene.draw();
} //end app()

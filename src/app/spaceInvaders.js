import {IonCloud} from './vendor/ionCloud';
import * as animations from './animations/';
import * as states from './states/';
import {missiles} from './missiles';

let scene = new IonCloud();

export {scene};

export function spaceInvaders(){
  scene.animate('flame',{
    startX: 250,
    startY: 200,
    width: 100,
    height: 120,
    color: 'rgba(250,50,0,0.05)',
    quality: 100
  });
  scene.animate('vortex',{
    startX: -250,
    startY: -250,
    size: 400,
    density: 200,
    iterations: 300,
    callback: function(){
      console.log('callback called');
      scene.animate('laser',{
        startX: -250,
        startY: -250,
        endX: -150,
        endY: 250,
        size: 10
      });
    }
  });
  scene.draw();
  scene.clearScene=function(){
    // Clear screen
    ctx.fillStyle='#000';
    ctx.fillRect(0,0,v.w,v.h);

    // Draw a ground
    ctx.fillStyle='rgba(10,80,10,0.7)';
    ctx.fillRect(0,v.h/4*3,v.w,v.h/4);
  };
  setInterval(function(){
    if(scene.camera.dx===0){
      scene.camera.x--;
    }else{
      scene.camera.x++;
    } //end if
    if(scene.camera.x<(v.w/2-100)||scene.camera.x>(v.w/2+100))scene.camera.dx^=1;
  },10);
  /*
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
  scene.makeState('lost',states.lost); */
  scene.draw();
} //end app()

import {Ion} from '../vendor/ion';
import {generateInvader} from './generateInvader';
import {IonCloud} from '../vendor/ionCloud';

export function makeItRain() {
  /*
  // The following will show at the bottom left of the screen
  var headerText = 'space-invaders Version 0.1.0 by Nathaniel Inman',
      makeItRain = new Ion(40),
      startingXLocations = [],
      startingYLocations = [];

  for(let x=0;x<10;x++){
    for(let y=0;y<5;y++){
      let dx = Math.floor(x*v.w/3*2/8),
          dy = Math.floor(y*v.h/3*2/8);

      startingXLocations.push(dx);
      startingYLocations.push(dy);
    } //end for
  } //end for

  // Declare and initialize the scene
  makeItRain.startX = ()=> r(1, v.w, 1);
  makeItRain.startY = 15;
  makeItRain.endX = ()=> startingXLocations.pop();
  makeItRain.endY = ()=> startingYLocations.pop();
  makeItRain.windX = ()=> r(0.02)-0.01;
  makeItRain.windY = ()=> r(0.02)-0.01;
  makeItRain.image = ()=> generateInvader();
  makeItRain.imageWidth = 40;
  makeItRain.imageHeight = 40;
  makeItRain.tweenDuration = 100;
  makeItRain.tweenType = 'ease-out-circular';
  makeItRain.onEnd = (particle)=>{
    particle.startX = particle.endX;
    particle.startY = particle.endY;
    particle.tweenDuration = Infinity;
  };
  makeItRain.clear = ()=>{
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, v.w, v.h);
    ctx.font = '18px Courier New';
    ctx.fillStyle = 'rgb(255,255,0)';
    ctx.fillText(headerText, 5, v.h - 5);
  };
  makeItRain.populate(()=> r(1,250));
  makeItRain.process(); //begin processing the scene
  */
  var scene = new IonCloud();
  scene.make('fire',250,200,100,120,'rgba(250,50,0,0.05)',100);
  scene.make('vortex',-250,-250,400,function(){
    scene.make('laser',-250,-250,-150,250);
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
    if(scene.camera.x<100||scene.camera.x>v.w-500)scene.camera.dx^=1;
  },10);
} //end app()

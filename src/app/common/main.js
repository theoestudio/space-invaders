import {Ion} from '../vendor/ion';
import {generateInvader} from './generateInvader';

export function makeItRain() {
  // The following will show at the bottom left of the screen
  var headerText = 'space-invaders Version 0.1.0 by Nathaniel Inman',
      shirtWidth = 0, shirtLeft = 0, // ease logical checks at runtime by
      logoWidth = 0, logoHeight = 0, // preprocessing the sizes of the images
      shirt = new Image(),
      logo = new Image(),
      dollar = new Image(),
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
  makeItRain.sx = ()=> r(1, v.w, 1);
  makeItRain.sy = 15;
  makeItRain.dx = ()=> startingXLocations.pop();
  makeItRain.dy = ()=> startingYLocations.pop();
  makeItRain.wx = ()=> 0 - 0.0025;
  makeItRain.wy = 0;
  makeItRain.image = ()=> generateInvader();
  makeItRain.imageWidth = 40;
  makeItRain.imageHeight = 40;
  makeItRain.tween_duration = 100;
  makeItRain.tween_type = 19;
  makeItRain.onEnd = function(particle){
    particle.sx = particle.dx;
    particle.sy = particle.dy;
    particle.d = Infinity;
  };
  makeItRain.onEscape = function(particle){
    //this.collection.splice(particle.id, 1, this.getNew(particle.id));
  };
  makeItRain.clear = function () { //overriding the clear frame function
    ctx.fillStyle = '#000';
    ctx.fillRect(0, 0, v.w, v.h);
    ctx.font = '18px Courier New';
    ctx.fillStyle = 'rgb(255,255,0)';
    ctx.fillText(headerText, 5, v.h - 5);
  };
  makeItRain.populate(()=> r(1,250));
  makeItRain.process(); //begin processing the scene
} //end app()

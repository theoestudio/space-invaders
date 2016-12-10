import {Ion} from '../ion';

export function vortex(name,sx,sy,s,d,t,callback){
  let iterations = t || Infinity,
      density = d || 200,
      cloud = new Ion(density),
      startX = sx || 0,
      startY = sy || 0,
      size = s || 300;

  cloud.clear = false;
  cloud.color = 'rgba(200,200,255,0.7)';
  cloud.startX = ()=> Math.abs(this.camera.x+r(-1*size/2,size/2)+startX)+1;
  cloud.startY = ()=> Math.abs(this.camera.y+r(-1*size/2,size/2)+startY)+1;
  cloud.endX = ()=> this.camera.x+startX;
  cloud.endY = ()=> this.camera.y+startY;
  cloud.size = ()=> r(1,5);
  cloud.tweenType = 'ease-out-circular';
  cloud.tweenDuration = ()=> r(100,200,true);
  cloud.onEnd = function onEnd(particle){
    if(iterations<50&&iterations>0){
      if(typeof callback === 'function') callback();
      iterations--;
    }else if(iterations>0){
      iterations--;
      this.reevaluate(particle);
    }else if(iterations===0){
      cloud.finished = true;
    }//end if
  };
  cloud.modulate = function modulate(particle){
    particle.endX = cloud.endX();
    particle.endY = cloud.endY();
  };
  cloud.populate();
  return cloud;
} //end vortex()

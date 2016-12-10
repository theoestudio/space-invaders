import {Ion} from '../ion';

export function vortex(name,sx,sy,s,callback){
  let status = 200,
      cloud = new Ion(status),
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
    if(status<50&&status>0){
      callback();
      status--;
    }else if(status>0){
      status--;
      this.reevaluate(particle);
    }else if(status===0){
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

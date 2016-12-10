import {Ion} from '../ion';

export function flame(name,sx,sy,w,h,color,quality){
  let flame = new Ion(2*(quality||100)),
      x = sx||0,
      y = sy||0,
      width= w||20,
      height= h||100;

  flame.clear = false;
  flame.color = color||'rgba(250,170,0,0.2)';
  flame.startX = ()=> this.camera.x+x+r(0,width)-width/2;
  flame.startY = ()=> this.camera.y+y;
  flame.endX = ()=> this.camera.x+x;
  flame.endY = ()=> this.camera.y+y-height;
  flame.windX = ()=> r(0,0.5)-0.25;
  flame.windY = ()=> r(0,2)-2;
  flame.tweenType = ()=> r(10,20,true);
  flame.tweenDuration = ()=> r(300,600,false);
  flame.onEscape = function onEscape(p){ this.onEnd(p); };
  flame.onEnd =  flame.reevaluate;
  flame.modulate = function modulate(particle){
    let size=(height+width)/4;

    // reset after we reach 15%
    if(particle.tweenCurrent>particle.tweenDuration*0.15){
      this.onEnd(particle);
    }else{
      particle.size=size-size/particle.tweenDuration*particle.tweenCurrent;
    } //end if
  };
  flame.populate();
  return flame;
} //end flame()

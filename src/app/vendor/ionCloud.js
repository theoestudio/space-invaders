import {Ion} from './ion';
import {clouds} from './clouds/index';

// Ion Cloud is a library of ion preconfigured clouds. These help in creating
// particle effects common in many applications
export class IonCloud{
  constructor(){
    this.camera = {
      x:v.w/2,
      y:v.h/2,
      dx:0,
      dy:0
    };
    this.collection=[];
    this.clouds = clouds;
  }
  make(type){
    this.collection.push(this.clouds[type].apply(this,arguments));
  }
  clearScene(){
    ctx.fillStyle='#000';
    ctx.fillRect(0,0,v.w,v.h);
  }
  draw(){
    this.clearScene();
    this.collection.forEach((animation,index,collection)=>{
      if(animation.finished){
        collection.splice(index,1);
      }else{
        animation.getFrame();
      } //end if
    });
    requestAnimationFrame(()=> this.draw());
  }
}

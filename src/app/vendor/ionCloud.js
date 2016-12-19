import * as clouds from './clouds/';

// Ion Cloud is a library of ion preconfigured clouds. These help in creating
// particle effects common in many applications
export class IonCloud{
  constructor(){
    this.camera = {
      x:v.w/2,
      y:v.h/2,
      dx:0, //direction x
      dy:0 //direction y
    };
    this.collection=[];
    this.beforeDraw={};
    this.clouds = clouds;
    this.state = 'initial';
  }
  animate(type){
    if(typeof type === 'string'){
      this.collection.push(this.clouds[type].apply(this,arguments));
    }else{
      this.collection.push(type.apply(this,arguments));
    } //end if
  }
  makeState(state,beforeDraw){
    this.beforeDraw[state]=beforeDraw; //mapper
  }
  clearScene(){
    ctx.fillStyle='#000';
    ctx.fillRect(0,0,v.w,v.h);
  }
  draw(){
    this.clearScene();
    if(this.beforeDraw[this.state]) this.beforeDraw[this.state]();
    this.collection.forEach((animation,index,collection)=>{
      if(animation.states.includes(this.state)){ //only render if its in current state
        if(animation.finished){
          if(typeof animation.onFinished === 'function') animation.onFinished();
          collection.splice(index,1);
        }else{
          animation.getFrame();
        } //end if
      } //end if
    });
    requestAnimationFrame(()=> this.draw());
  }
}

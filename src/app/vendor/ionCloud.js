import {Ion} from './ion';

/**
 * Ion Cloud is a library of Ion preconfigured templates. These help in creating
 * particle effects common in many applications.
 */
export class IonCloud{
  constructor(){
    this.camera = {
      x:v.w/2,
      y:v.h/2,
      dx:0,
      dy:0
    };
    this.objects=[];
    this.template={
      fire(name,sx,sy,w,h,color,quality){
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
      },
      vortex(name,sx,sy,s,callback){
        let status = 200,
            cloud = new Ion(status),
            startX = sx || 0,
            startY = sy || 0,
            size = s || 300;

        cloud.clear = false;
        cloud.color = 'rgba(200,200,255,0.7)';
        cloud.startX = ()=> this.camera.x+r(-1*size/2,size/2)+startX;
        cloud.startY = ()=> this.camera.y+r(-1*size/2,size/2)+startY;
        cloud.endX = ()=> this.camera.x+startX;
        cloud.endY = ()=> this.camera.y+startY;
        cloud.size = ()=> r(1,5);
        cloud.tweenType = 'ease-out-circular';
        cloud.tweenDuration = ()=> r(100,200,true);
        cloud.onEnd = function onEnd(particle){
          if(status<50&&status>0){
            cloud.color = `rgba(200,200,255,${1/20*status})`;
            callback();
            status--;
          }else if(status>0){
            status--;
            this.reset(particle);
          }//end if
        };
        cloud.modulate = function modulate(particle){
          particle.endX = cloud.endX();
          particle.endY = cloud.endY();
        };
        cloud.populate();
        return cloud;
      },
      laser(name,sx,sy,dx,dy,s){
        let status = 200,
            beam = new Ion(status),
            startX = sx || 0,
            startY = sy || 0,
            endX = dx || 0,
            endY = dy || 0,
            size = s || 10;

        beam.clear = false;
        beam.color = 'rgba(250,250,150,0.5)';
        beam.startX = ()=> this.camera.x+endX;
        beam.startY = ()=> this.camera.y+endY;
        beam.endX = ()=> this.camera.x+endX-size/2+r(size);
        beam.endY = ()=> this.camera.y+endY-size/2+r(size);
        beam.windX = ()=> r(0,1.5)-0.75;
        beam.windY = ()=> r(0,1.5)-0.75;
        beam.size = ()=> r(2,4);
        beam.tweenType = ()=> r(10,15,false);
        beam.tweenDuration = ()=> r(100,150,false);
        beam.onEscape = function onEscape(p){ this.onEnd(p); };
        beam.onEnd = function onEnd(){};
        beam.onCreate = ()=> status--;
        beam.populate();
        return {
          getFrame: ()=>{
            ctx.strokeStyle='rgba(100,100,250,'+0.1/200*status+')';
            ctx.lineWidth=17;
            if(status>0){
              ctx.beginPath();
              ctx.moveTo(this.camera.x+startX+3,this.camera.y+startY);
              ctx.lineTo(this.camera.x+endX+3,this.camera.y+endY);
              ctx.stroke();
              ctx.strokeStyle='#DDF';
              ctx.lineWidth=2;
              ctx.beginPath();
              ctx.moveTo(this.camera.x+startX+3,this.camera.y+startY);
              ctx.lineTo(this.camera.x+endX+3,this.camera.y+endY);
              ctx.stroke();
            } //end if
            beam.getFrame();
          } //end getFrame()
        }; //end return;
      }
    }; //end this.templates
  }
  make(type){
    this.objects.push(this.template[type].apply(this,arguments));
  }
  clearScene(){
    ctx.fillStyle='#000';
    ctx.fillRect(0,0,v.w,v.h);
  }
  draw(){
    this.clearScene();
    for(let ion in this.objects) this.objects[ion].getFrame();
    requestAnimationFrame(()=> this.draw());
  }
}

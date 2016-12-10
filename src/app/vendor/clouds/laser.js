import {Ion} from '../ion';

export function laser(name,sx,sy,dx,dy,s){
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
} //end laser()

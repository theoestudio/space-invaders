import {invaders} from './invaders';
import {IonCloud} from '../vendor/ionCloud';
import {Ion} from '../vendor/ion';

let missiles = [];

export function spaceInvaders() {
  let scene = new IonCloud();

  scene.make(zoomIntoSpace,()=>{
    scene.make(zigZag);
    scene.make(missileAttacks);
  });
  scene.draw();
} //end app()

function zoomIntoSpace(__this,callback){
  let zoomIntoSpace = new Ion();

  zoomIntoSpace.status = invaders.length;
  zoomIntoSpace.collection = invaders;
  zoomIntoSpace.onFinished = callback;
  return zoomIntoSpace;
} //end zoomIntoSpace()

function missileAttacks(){
  let missileAttacks = new Ion();

  (function generateMissile(){
    let m = {}, invader = invaders.getRandom();

    m.id = missiles.length;
    m.x = m.originX = m.startX = m.terminalX = m.endX = invader.x;
    m.y = m.originY = m.startY = invader.y;
    m.endY = m.terminalY = v.h;
    m.tweenCurrent = 0;
    m.tweenDuration = 200;
    m.tweenType = 'linear';
    m.size = 5;
    m.color = '#f00';
    m.windX = m.windY = 0;
    m.onEnd = function onEnd(particle){
      this.collection.splice(particle.id,1);
      this.collection.forEach((p,i)=> p.id=i); //re-index array
    };
    missiles.push(m);
    setTimeout(generateMissile,r(1000,3000,true));
    console.log(missiles.length);
  })();
  missileAttacks.collection = missiles;
  return missileAttacks;
} //end missiles()

function zigZag(){
  let zigZag = new Ion();

  invaders.map(invader=>{
    invader.x = invader.startX = invader.originX = invader.endX;
    invader.y = invader.startY = invader.originY = invader.endY;
    invader.endX = invader.terminalX = invader.terminalX - (v.w/6)|0;
    invader.tweenCurrent = 0;
    invader.tweenDuration = 100;
    invader.tweenType = 'ease-in-out-cubic';
    invader.state = 'left';
    invader.onEnd = function invaderFinished(invader){
      invader.x = invader.startX = invader.originX = invader.endX;
      invader.y = invader.startY = invader.originY = invader.endY;
      if(invader.state==='left'){
        invader.state = 'down-left';
        invader.endY = invader.terminalY = invader.terminalY + invader.imageHeight;
        invader.tweenDuration = 50;
        invader.tweenType = 'ease-out-cubic';
      }else if(invader.state==='down-left'){
        invader.state = 'right';
        invader.endX = invader.terminalX = invader.terminalX + (v.w/6*2)|0;
        invader.tweenDuration = 200;
        invader.tweenType = 'ease-in-out-cubic';
      }else if(invader.state==='right'){
        invader.state = 'down-right';
        invader.endY = invader.terminalY = invader.terminalY + invader.imageHeight;
        invader.tweenDuration = 50;
        invader.tweenType = 'ease-out-cubic';
      }else if(invader.state==='down-right'){
        invader.state = 'left';
        invader.endX = invader.terminalX = invader.terminalX - (v.w/6*2)|0;
        invader.tweenDuration = 200;
        invader.tweenType = 'ease-in-out-cubic';
      } //end if
      invader.tweenCurrent = 0;
    };
  });
  zigZag.collection = invaders;
  return zigZag;
} //end zigZag()

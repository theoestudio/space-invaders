import {invaders} from './invaders';
import {IonCloud} from '../vendor/ionCloud';
import {Ion} from '../vendor/ion';

export function spaceInvaders() {
  let scene = new IonCloud();

  scene.make(zoomIntoSpace,()=> scene.make(zigZag));
  scene.draw();
} //end app()

function zoomIntoSpace(__this,callback){
  let zoomIntoSpace = new Ion();

  zoomIntoSpace.status = invaders.length;
  zoomIntoSpace.collection = invaders;
  zoomIntoSpace.onFinished = callback;
  return zoomIntoSpace;
} //end zoomIntoSpace()

function zigZag(){
  let zigZag = new Ion(), state = 'left';

  invaders.map(invader=>{
    invader.x = invader.startX = invader.originX = invader.endX;
    invader.y = invader.startY = invader.originY = invader.endY;
    invader.endX = invader.terminalX = invader.terminalX - (v.w/6)|0;
    invader.tweenCurrent = 0;
    invader.tweenDuration = 200;
    invader.tweenType = 'linear';
    invader.onEnd = function invaderFinished(invader){
      invader.x = invader.startX = invader.originX = invader.endX;
      invader.y = invader.startY = invader.originY = invader.endY;
      if(state==='left'){
        state = 'down-left';
        invader.endY = invader.terminalY = invader.terminalY + 100;
      }else if(state==='down-left'){
        state = 'right';
        invader.endX = invader.terminalX = invader.terminalX + (v.w/6*2)|0;
        console.log('debuggery',invader);
      }else if(state==='right'){
        state = 'down-right';
        invader.endY = invader.terminalY = invader.terminalY + 100;
      }else if(state==='down-right'){
        state = 'left';
        invader.endX = invader.terminalX = invader.terminalX - (v.w/6*2)|0;
      } //end if
      console.log('x: ',invader.startX|0,'->',invader.endX|0);
      console.log('y: ',invader.startY|0,'->',invader.endY|0);
      invader.tweenCurrent = 0;
    };
  });
  zigZag.collection = invaders;
  return zigZag;
} //end zigZag()

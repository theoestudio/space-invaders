import {invaders} from './invaders';
import {IonCloud} from '../vendor/ionCloud';
import {Ion} from '../vendor/ion';
import {shields} from './shields';

console.log('shields',shields);

let missiles = [];

export function spaceInvaders() {
  let scene = new IonCloud();

  scene.make(zoomIntoSpace,()=>{
    scene.make(zigZag);
    scene.make(missileAttacks);
  });
  scene.clearScene = function clearScene(){
    // Clear screen
    ctx.fillStyle='#000';
    ctx.fillRect(0,0,v.w,v.h);

    // Draw a ground
    ctx.fillStyle='rgba(10,80,10,0.7)';
    ctx.fillRect(0,v.h-10,v.w,10);

    // Detect missile collision
    missiles.forEach((m,mi,mo)=>{
      if(m.y>v.h-200){ //don't even bother until low enough
        shields.some(s=>{ //shield
          return s.stacks.some((s,si,so)=>{ //stack
            let b = s.bricks[0]; //only top brick can ever be hit

            if(b.x<=m.x&&b.y<=m.y&&b.x+b.width>=m.x&&b.y+b.height>=m.y){
              s.bricks.shift();
              mo.splice(mi,1);
              if(s.bricks.length===0) so.splice(si,1);
              return true; //found right stack bricks missile would be hit
            } //end if
          });
        });
      } //end if
    });

    // Draw shields
    ctx.fillStyle='#2dbfd4';
    shields.forEach(shield=>{
      shield.stacks.forEach(stack=>{
        stack.bricks.forEach(b=>{ //render brick
          ctx.fillRect(b.x,b.y,b.width,b.height);
        });
      });
    });
  };
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
    m.endY = m.terminalY = m.y+v.h;
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
    setTimeout(generateMissile,r(50,100,true));
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

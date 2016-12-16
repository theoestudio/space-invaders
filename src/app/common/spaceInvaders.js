import {invaders} from './invaders';
import {IonCloud} from '../vendor/ionCloud';
import {Ion} from '../vendor/ion';
import {shields} from './shields';

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
    ctx.fillStyle='rgb(10,80,10)';
    ctx.fillRect(0,v.h-10,v.w,10);

    // Detect invader collision with shields
    invaders.forEach((i,ii,io)=>{
      if(i.y+i.imageHeight>v.h-200){ //don't bother if not low enough
        shields.forEach(s=>{ //shield
          s.stacks.forEach((s,si,so)=>{ //stack
            s.bricks.forEach((b,bi,bo)=>{ //brick
              let l1 = b.x,         l2 = i.x,
                  r1 = b.x+b.width, r2 = i.x+i.width,
                  t1 = b.y,         t2 = i.y,
                  b1 = b.y+b.height,b2 = i.y+i.height,
                  result = false;

              // for collision, need to check all corners of one square
              // to see if any of the corners are within the other
              if(r1>=l2 && b1>=t2 && t1<=t2 && l1<=l2){
                result = true;bo.splice(bi,1);console.log('killed brick');
              }else if(r1>=r2 && b1>=t2 && t1<=t2 && l1<=r2){
                result = true;bo.splice(bi,1);console.log('killed brick');
              }else if(r1>=l2 && b1>=b2 && t1<=b2 && l1<=l2){
                result = true;bo.splice(bi,1);console.log('killed brick');
              }else if(r1>=r2 && b1>=b2 && t1<=b2 && l1<=r2){
                result = true;bo.splice(bi,1);console.log('killed brick');
              } //end if
              return true;
            });
          });
        });
      } //end if
    });

    // Detect missile collision with shields
    missiles.forEach((m,mi,mo)=>{
      if(m.y>v.h-10){ //missile hit the ground
        mo.splice(mi,1); //remove missile
      }else if(m.y>v.h-200){ //don't even bother until low enough
        shields.some(s=>{ //shield
          return s.stacks.some((s,si,so)=>{ //stack
            let b = s.bricks[0]; //only top brick can ever be hit

            if(b.x<=m.x&&b.y<=m.y&&b.x+b.width>=m.x&&b.y+b.height>=m.y){
              s.bricks.shift(); //remove destroyed brick
              mo.splice(mi,1); //remove missile
              if(s.bricks.length===0) so.splice(si,1);
              return true; //deleted a brick, short circuit
            } //end if
          });
        });
      } //end if
    });

    // Draw shields
    ctx.fillStyle='#2dbfd4';
    shields.forEach(shield=>{
      shield.stacks.forEach(stack=>{
        stack.bricks.forEach(b=> ctx.fillRect(b.x,b.y,b.width,b.height));
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
    let m = {}, invader = invaders.getRandom(),
        sx = invader.x+invader.imageWidth/2,
        sy = invader.y+invader.imageHeight;

    m.id = missiles.length;
    m.x = m.originX = m.startX = m.terminalX = m.endX = sx;
    m.y = m.originY = m.startY = sy;
    m.endY = m.terminalY = m.y+v.h;
    m.tweenCurrent = 0;
    m.tweenDuration = 200;
    m.tweenType = 'linear';
    m.color = '#ffA';
    m.size = 3;
    m.windX = m.windY = 0;
    m.onEnd = function onEnd(particle){
      this.collection.splice(particle.id,1);
      this.collection.forEach((p,i)=> p.id=i); //re-index array
    };
    missiles.push(m);
    setTimeout(generateMissile,r(100,500,true));
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
    invader.tweenDuration = 100; //400
    invader.tweenType = 'ease-in-out-cubic';
    invader.state = 'left';
    invader.onEnd = function invaderFinished(invader){
      invader.x = invader.startX = invader.originX = invader.endX;
      invader.y = invader.startY = invader.originY = invader.endY;
      if(invader.state==='left'){
        invader.state = 'down-left';
        invader.endY = invader.terminalY = invader.terminalY + invader.imageHeight;
        invader.tweenDuration = Math.floor(invader.tweenDuration/3);
        invader.tweenType = 'ease-out-cubic';
      }else if(invader.state==='down-left'){
        invader.state = 'right';
        invader.endX = invader.terminalX = invader.terminalX + (v.w/6*2)|0;
        invader.tweenDuration = Math.floor(invader.tweenDuration*3)-50;
        invader.tweenType = 'ease-in-out-cubic';
      }else if(invader.state==='right'){
        invader.state = 'down-right';
        invader.endY = invader.terminalY = invader.terminalY + invader.imageHeight;
        invader.tweenDuration = Math.floor(invader.tweenDuration/3);
        invader.tweenType = 'ease-out-cubic';
      }else if(invader.state==='down-right'){
        invader.state = 'left';
        invader.endX = invader.terminalX = invader.terminalX - (v.w/6*2)|0;
        invader.tweenDuration = Math.floor(invader.tweenDuration*3)-50;
        invader.tweenType = 'ease-in-out-cubic';
      } //end if
      if(invader.tweenDuration<50) invader.tweenDuration = 50;
      invader.tweenCurrent = 0;
    };
  });
  zigZag.collection = invaders;
  return zigZag;
} //end zigZag()

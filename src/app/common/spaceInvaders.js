import {Ion} from '../vendor/ion';
import {IonCloud} from '../vendor/ionCloud';
import {player} from './player';
import {shields} from './shields';
import {invaders} from './invaders';
import {missiles} from './missiles';

export function spaceInvaders() {
  let scene = new IonCloud();

  scene.animate(playerMovement);
  scene.animate(zoomIntoSpace,()=>{
    scene.state = 'started';
    scene.animate(zigZag);
    scene.animate(missileAttacks);
    missiles.startGeneration();
  });
  scene.makeState('initial',function beforeDraw(){
  });
  scene.makeState('started',function beforeDraw(){
    // Draw a ground
    ctx.fillStyle='rgb(10,80,10)';
    ctx.fillRect(0,v.h-10,v.w,10);

    // Detect invader collision with shields
    invaders.forEach((i,ii,io)=>{
      if(i.y+i.imageHeight>v.h-200){ //don't bother if not low enough
        shields.forEach(s=>{ //shield
          s.stacks.forEach((s,si,so)=>{ //stack
            s.bricks.every((b,bi,bo)=>{ //brick
              let l1 = i.x,              l2 = b.x,
                  r1 = i.x+i.imageWidth, r2 = b.x+b.width,
                  t1 = i.y,              t2 = b.y,
                  b1 = i.y+i.imageHeight,b2 = b.y+b.height,
                  result = false;

              // for collision, need to check all corners of one square
              // to see if any of the corners are within the other
              if(r1>=l2 && b1>=t2 && t1<=t2 && l1<=l2){
                result = true;bo.splice(bi,1);
              }else if(r1>=r2 && b1>=t2 && t1<=t2 && l1<=r2){
                result = true;bo.splice(bi,1);
              }else if(r1>=l2 && b1>=b2 && t1<=b2 && l1<=l2){
                result = true;bo.splice(bi,1);
              }else if(r1>=r2 && b1>=b2 && t1<=b2 && l1<=r2){
                result = true;bo.splice(bi,1);
              } //end if
              if(s.bricks.length===0) so.splice(si,1); //remove empty stack
              return true;
            });
          });
        });
      } //end if
    });

    // Detect missile collision
    missiles.forEach((m,mi,mo)=>{
      if(m.y>v.h-10){ //missile hit the ground
        mo.splice(mi,1); //remove missile
      }else if(m.y<v.h-200&&m.y>m.endY){ //detecting missile/invader collision
        invaders.some((i,ii,io)=>{ //invader
          if(i.x<=m.x&&i.y<=m.y&&i.x+i.imageWidth>=m.x&&i.y+i.imageHeight>=m.y){
            io.splice(ii,1); //destroy invader
            mo.splice(mi,1); //destroy missile
            if(io.length===0) scene.state = 'won';
            return true; //collision detected, short circuit
          } //end if
        });
      }else if(m.y>v.h-200){ //detecting shield collision
        let p = player;

        if(p.x<=m.x&&p.y<=m.y&&p.x+p.imageWidth>=m.x&&p.y+p.imageHeight>=m.y){
          scene.state = 'lost';
          return true;
        } //end if
        shields.some(s=>{ //shield
          return s.stacks.some((s,si,so)=>{ //stack
            if(m.y<m.endY){ //invader missile
              let b = s.bricks[0]; //only top brick can ever be hit

              if(b.x<=m.x&&b.y<=m.y&&b.x+b.width>=m.x&&b.y+b.height>=m.y){
                s.bricks.shift(); //remove destroyed brick
                mo.splice(mi,1); //remove missile
                if(s.bricks.length===0) so.splice(si,1);
                return true; //deleted a brick, short circuit
              } //end if
            }else{ //player missile
              let b = s.bricks[s.bricks.length-1]; //only bottom brick can hit

              if(b.x<=m.x&&b.y<=m.y&&b.x+b.width>=m.x&&b.y+b.height>=m.y){
                s.bricks.pop(); //remove destroyed brick
                mo.splice(mi,1); //remove missile
                if(s.bricks.length===0) so.splice(si,1);
                return true; //deleted a brick, short circuit
              } //end if
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
  });
  scene.makeState('won',function beforeDraw(){
    ctx.fillStyle='#9F9';
    ctx.textAlign='center';
    ctx.textBaseline='middle';
    ctx.font = '48px Arial';
    ctx.fillText('You Won!',v.w/2,v.h/2);
  });
  scene.makeState('lost',function beforeDraw(){
    ctx.fillStyle='#F99';
    ctx.textAlign='center';
    ctx.textBaseline='middle';
    ctx.font = '48px Arial';
    ctx.fillText('You Lost!',v.w/2,v.h/2);
  });
  scene.draw();
} //end app()

function playerMovement(__this,callback){
  let playerMovement = new Ion();

  playerMovement.states = ['initial','started'];
  playerMovement.collection = [player];
  playerMovement.onFinished = callback;
  return playerMovement;
} //end playerMovement()

function zoomIntoSpace(__this,callback){
  let zoomIntoSpace = new Ion();

  zoomIntoSpace.states = ['initial'];
  zoomIntoSpace.status = invaders.length;
  zoomIntoSpace.collection = invaders;
  zoomIntoSpace.onFinished = callback;
  return zoomIntoSpace;
} //end zoomIntoSpace()

function missileAttacks(){
  let missileAttacks = new Ion();

  missileAttacks.states = ['started'];
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
  zigZag.states = ['started'];
  zigZag.collection = invaders;
  return zigZag;
} //end zigZag()

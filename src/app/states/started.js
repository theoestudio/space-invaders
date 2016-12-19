import {invaders} from '../invaders';
import {missiles} from '../missiles';
import {player} from '../player';
import {shields} from '../shields';
import {scene} from '../spaceInvaders';

export function started(){
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
} //end started()
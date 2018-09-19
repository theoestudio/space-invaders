/* eslint-disable no-invalid-this */
export function started(){
  const {dayCycle,easel,player,missiles,shields,invaders} = this,
        {ctx,viewport} = easel;

  // Draw background
  dayCycle.drawNext(true);

  // Draw a ground
  ctx.fillStyle='rgb(10,80,10)';
  ctx.fillRect(0,viewport.h-10,viewport.w,10);

  // Draw score
  const bgColor = ctx.getImageData(15,15,1,1).data,
        average = (bgColor[0]+bgColor[1]+bgColor[2])/3/255;

  ctx.textAlign = 'left';
  ctx.font = '24px Orbitron';
  ctx.textBaseline = 'top';
  if(average>0.5){
    ctx.fillStyle='#000';
  }else{
    ctx.fillStyle='#fff';
  } //end if
  ctx.fillText(`SCORE: ${player.score}`,15,15);

  // Detect invader collision with shields
  invaders.list.forEach(i=>{
    if(i.y+i.imageHeight>viewport.h-200){ //don't bother if not low enough
      const p = player,
            l1 = i.x,
            r1 = i.x+i.imageWidth,
            t1 = i.y,
            b1 = i.y+i.imageHeight;

      let l2 = p.x,
          r2 = p.x+p.imageWidth,
          t2 = p.y,
          b2 = p.y+p.imageHeight,
          result = false;

      // for collision, need to check all corners of one square
      // to see if any of the corners are within the other
      if(r1>=l2 && b1>=t2 && t1<=t2 && l1<=l2){
        result = true;this.state = 'lost';
      }else if(r1>=r2 && b1>=t2 && t1<=t2 && l1<=r2){
        result = true;this.state = 'lost';
      }else if(r1>=l2 && b1>=b2 && t1<=b2 && l1<=l2){
        result = true;this.state = 'lost';
      }else if(r1>=r2 && b1>=b2 && t1<=b2 && l1<=r2){
        result = true;this.state = 'lost';
      } //end if
      if(!result){
        shields.forEach(s=>{ //shield
          s.stacks.forEach((s,si,so)=>{ //stack
            s.bricks.every((b,bi,bo)=>{ //brick
              l2 = b.x;
              r2 = b.x+b.width;
              t2 = b.y;
              b2 = b.y+b.height;
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
            }); //end bricks
          }); //end stacks
        }); //end shields
      } //end if
    } //end if
  });

  // Detect missile collision
  missiles.list.forEach((m,mi,mo)=>{

    // Start with detecting the players or invaders missiles collding
    // with the shields, ground or the player
    if(m.y>viewport.h-10){ //missile hit the ground
      mo.splice(mi,1); //remove missile
    }else if(m.y>viewport.h-200){ //detecting shield collision
      const p = player;

      if(p.x<=m.x&&p.y<=m.y&&p.x+p.imageWidth>=m.x&&p.y+p.imageHeight>=m.y){
        this.state = 'lost';
        return true;
      } //end if
      shields.some(s=>{ //shield
        return s.stacks.some((s,si,so)=>{ //stack
          let stackResult = false;

          if(m.y<m.endY){ //invader missile
            const b = s.bricks[0]; //only top brick can ever be hit

            if(b.x<=m.x&&b.y<=m.y&&b.x+b.width>=m.x&&b.y+b.height>=m.y){
              s.bricks.shift(); //remove destroyed brick
              mo.splice(mi,1); //remove missile
              if(s.bricks.length===0) so.splice(si,1);
              stackResult = true; //deleted a brick, short circuit
            } //end if
          }else{ //player missile
            const b = s.bricks[s.bricks.length-1]; //only bottom brick can hit

            if(b.x<=m.x&&b.y<=m.y&&b.x+b.width>=m.x&&b.y+b.height>=m.y){
              s.bricks.pop(); //remove destroyed brick
              mo.splice(mi,1); //remove missile
              if(s.bricks.length===0) so.splice(si,1);
              stackResult = true; //deleted a brick, short circuit
            } //end if
          } //end if
          return stackResult;
        });
      });
    } //end if

    // Now detect players missiles colliding with invaders
    if(m.y>m.endY){ //detecting missile/invader collision
      invaders.list.some((i,ii,io)=>{ //invader
        let invaderResult = false;

        if(i.x<=m.x&&i.y<=m.y&&i.x+i.imageWidth>=m.x&&i.y+i.imageHeight>=m.y){
          io.splice(ii,1); //destroy invader
          mo.splice(mi,1); //destroy missile
          player.score+=100;
          if(io.length===0) this.state = 'won';
          invaderResult = true; //collision detected, short circuit
        } //end if
        return invaderResult;
      });
    } //end if
    return true;
  });

  // Draw shields
  ctx.fillStyle='#2dbfd4';
  shields.forEach(shield=>{
    shield.stacks.forEach(stack=>{
      stack.bricks.forEach(b=> ctx.fillRect(b.x,b.y,b.width,b.height));
    });
  });
} //end started()

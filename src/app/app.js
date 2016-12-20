import 'file-loader?name=[name].html!./index.jade';
import './app.styl';
import {easel} from 'ion-cloud';

// Launch application if easel was able to create a canvas,
// if it wasn't then we know canvas isn't supported
let noscript = document.getElementById('noscript');

if(!easel.activated){
  noscript.innerHTML = `
  <p class="browsehappy">
    You are using an outdated browser. Please
    <a href="http://browsehappy.com/"> upgrade your browser</a>
    to improve your experience.
    <span style="color:red;"><br/>Canvas isn't supported in your browser.</span>
  </p>`;
}else{
  noscript.style.visibility='hidden';
  let color = {cur: rndHex(), tar: rndHex()};

  easel.config = ()=>{
    ctx.fontRatio = 0.2;
    ctx.textAlign = 'center';
    ctx.fontSize = Math.min(v.w,v.h)*ctx.fontRatio;
    ctx.font = ctx.fontSize + 'px Impact, Charcoal, sans-serif';
  };
  easel.onDraw = ()=>{
    ctx.fillStyle = ink(color.cur,1,0.3,0.4);
    ctx.fillRect(0,0,v.w,v.h);
    ctx.fillStyle = ink(color.cur,1,0.5,0.6);
    ctx.fillText(color.cur,v.w/2,v.h/2+ctx.fontSize/4);
  };
  (function main(){
    if(color.cur!==color.tar){
      let c = ink(color.cur,{o:1}),
          t = ink(color.tar,{o:1});

      c.r=c.r<t.r?++c.r:c.r>t.r?--c.r:c.r;
      c.g=c.g<t.g?++c.g:c.g>t.g?--c.g:c.g;
      c.b=c.b<t.b?++c.b:c.b>t.b?--c.b:c.b;
      color.cur='#'+[c.r,c.g,c.b].map(x=>x.toString(16)).map(x=>x.length<2?'0'+x:x).join('');
      if(!(c.r^t.r&&c.g^t.g&&c.b^t.b))color.tar=rndHex();
    }else{
      color.tar=rndHex();
    } //end if
    easel.redraw();
    requestAnimationFrame(main);
  })();
} //end if

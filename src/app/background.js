import {Phaser} from 'ion-cloud';

let topColor = {
      current: {r:  0,g:  0,b:  0},
      dawn:    {r:119,g:153,b:187},
      daytime: {r:204,g:238,b:255},
      dusk:    {r:135,g: 51,b: 85},
      midnight:{r:  0,g:  0,b: 17}
    },
    bottomColor = {
      current: {r:  0,g:  0,b:  0},
      dawn:    {r: 85,g: 85,b: 120},
      daytime: {r: 50,g: 85,b:170},
      dusk:    {r:  0,g: 17,b: 34},
      midnight:{r:153,g: 87,b: 22}
    },
    colors = [topColor,bottomColor],
    drawFn = ()=> [0,0,v.w,v.h],
    gradientFn = ()=> ctx.createLinearGradient(0,0,0,v.h/5*4),
    dayCycle = new Phaser(500,'dawn',colors,ctx,drawFn,gradientFn);

export {dayCycle};

import {Easel,Ion,IonCloud} from 'ion-cloud/src/lib';
import {Missile,MissileList} from './Missile';
import {Player} from './Player';
import {invaders} from './invaders';
import {generateShields} from './generateShields';
import {generateBackground} from './generateBackground';
import * as animations from './animations/';
import * as states from './states/';

const easel = new Easel(),
      scene = new IonCloud(easel,Ion),
      player = new Player(easel),
      missiles = new MissileList(easel,player);

// now apply the variables to the scene itself so they
// can be accessed during the animations
scene.player = player;
scene.missiles = missiles;
scene.shields = generateShields(easel);
scene.background = generateBackground(easel);

// go ahead and start all the animations and begin
scene.animate(animations.playerMovement);
scene.animate(animations.zoomIntoSpace,()=>{
  scene.state = 'started';
  scene.animate(animations.zigZag);
  scene.animate(animations.missileAttacks);
  (function generateMissile(){
    if(invaders.length) missiles.add(new Missile(easel,player,missiles,invaders));
    setTimeout(()=>generateMissile.call((this),r(100,500),true));
  })();
});
scene.makeState('initial',states.initial);
scene.makeState('started',states.started);
scene.makeState('won',states.won);
scene.makeState('lost',states.lost);
scene.draw();

document.addEventListener('keydown', e=>{
  if(e.code==='ArrowRight'){
    player.moveRight();
  }else if(e.code==='ArrowLeft'){
    player.moveLeft();
  }else if(e.code==='Space'){
    missiles.shootFrom(player);
  } //end if
});

document.addEventListener('touchstart',clickEvent,false);
document.addEventListener('click',clickEvent,false);
window.addEventListener('resize', ()=> window.location.reload(), false);

function clickEvent(e){
  if(scene.state==='lost'){
    window.location.reload();
  }else{
    const delta = Math.abs(player.x-e.clientX);

    if(delta>50&&e.clientX>player.x){
      player.moveRight();
    }else if(delta>50&&e.clientX<player.x){
      player.moveLeft();
    } //end if
    missiles.shootFrom(player);
  } //end if
} //end clickEvent()


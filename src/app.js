import {Easel,Ion,IonCloud} from 'ion-cloud/src/lib';
import {Player} from './Player';
import {MissileList} from './MissileList';
import {InvaderList} from './InvaderList';
import {generateShields} from './generateShields';
import {generateBackground} from './generateBackground';
import * as animations from './animations/';
import * as states from './states/';

const easel = new Easel(),
      scene = new IonCloud(easel,Ion);

// now apply the variables to the scene itself so they
// can be accessed during the animations
scene.player = new Player(easel);
scene.invaders = new InvaderList(easel);
scene.missiles = new MissileList(easel,scene.player,scene.invaders);
scene.shields = generateShields(easel);
scene.dayCycle = generateBackground(easel);

// start by attributing the animations to the scene so we can access them
scene.clouds = {
  playerMovement: animations.playerMovement,
  zoomIntoSpace: animations.zoomIntoSpace,
  missileAttacks: animations.missileAttacks,
  zigZag: animations.zigZag
};

// go ahead and start all the animations and begin
scene.animate('playerMovement');
scene.animate('zoomIntoSpace',{
  onFinished(){
    scene.state = 'started';
    scene.animate('zigZag');
    scene.animate('missileAttacks');
    scene.missiles.startGenerating();
  }
});
scene.makeState('initial',()=>states.initial.call(scene));
scene.makeState('started',()=>states.started.call(scene));
scene.makeState('won',()=>states.won.call(scene));
scene.makeState('lost',()=>states.lost.call(scene));
scene.draw();

document.addEventListener('keydown', e=>{
  if(e.code==='ArrowRight'){
    scene.player.moveRight();
  }else if(e.code==='ArrowLeft'){
    scene.player.moveLeft();
  }else if(e.code==='Space'){
    scene.missiles.shootFrom(scene.player);
  } //end if
});

document.addEventListener('touchstart',clickEvent,false);
document.addEventListener('click',clickEvent,false);
window.addEventListener('resize', ()=> window.location.reload(), false);

function clickEvent(e){
  if(scene.state==='lost'){
    window.location.reload();
  }else{
    const delta = Math.abs(scene.player.x-e.clientX);

    if(delta>50&&e.clientX>scene.player.x){
      scene.player.moveRight();
    }else if(delta>50&&e.clientX<scene.player.x){
      scene.player.moveLeft();
    } //end if
    scene.missiles.shootFrom(scene.player);
  } //end if
} //end clickEvent()


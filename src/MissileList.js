export class Missile {
  constructor (easel, player, missiles, invaders, id = 0) {
    const origin = player || invaders.getRandom();
    const sx = origin.x + origin.imageWidth / 2;
    const sy = origin.y + (player ? -2 : origin.imageHeight);

    this.easel = easel;
    this.id = id;
    this.x = this.originX = this.startX = this.terminalX = this.endX = sx;
    this.y = this.originY = this.startY = sy;
    if (player) {
      this.endY = this.terminalY = this.y - this.easel.viewport.h;
    } else {
      this.endY = this.terminalY = this.y + this.easel.viewport.h;
    } // end if
    this.tweenCurrent = 0;
    this.tweenDuration = 200;
    this.tweenType = 'linear';
    this.color = '#ffa';
    this.size = 3;
    this.onEnd = function onEnd (particle) {
      this.collection.splice(particle.id, 1);

      // eslint-disable-next-line no-return-assign
      this.collection.forEach((p, i) => p.id = i);
    };
  }
}

export class MissileList {
  constructor (easel, player, invaders) {
    this.easel = easel;
    this.list = [];
    this.player = player;
    this.invaders = invaders;
  }

  shootFrom () {
    if (this.invaders.list.length) {
      this.list.push(new Missile(this.easel, this.player, this.list.length));
    } // end if
  }

  add (missile) {
    this.list.push(missile);
  }

  startGenerating () {
    if (this.invaders.list.length) {
      this.list.push(
        new Missile(this.easel, null, this.list, this.invaders)
      );
    } // end if
    setTimeout(() => {
      const num = Math.floor(Math.random() * 400 + 100);

      this.startGenerating(num, true);
    }, 500);
  }
}

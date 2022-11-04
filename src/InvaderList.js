import { generateInvader } from './generateInvader';

export class Invader {
  constructor ({ easel, id, dx = 0, dy = 0, color, image }) {
    this.easel = easel;
    this.id = id;
    this.x = this.originX = this.startX = 1 + Math.floor(Math.random() * easel.viewport.w);
    this.y = this.originY = this.startY = 15;
    this.terminalX = this.endX = dx;
    this.terminalY = this.endY = dy;
    this.tweenCurrent = 0;
    this.tweenDuration = 100;
    this.tweenType = 'ease-out-circular';
    this.color = color;
    this.image = image;
    if (easel.viewport.w > 800) {
      this.imageWidth = 40;
      this.imageHeight = 40;
    } else {
      this.imageWidth = 20;
      this.imageHeight = 20;
    } // end if
  }
}

export class InvaderList {
  constructor (easel) {
    this.easel = easel;
    this.types = 4;
    this.colors = [
      '#ee1f30', '#fab630', '#43af52', '#2dbfd4'
    ];
    this.images = Array.from(new Array(this.types), () => generateInvader());
    this.list = [];
    this.initialize();
  }

  initialize () {
    for (let y = 0; y < 4; y++) {
      for (let x = 0; x < 10; x++) {
        const dx = Math.floor(x * this.easel.viewport.w / 3 * 2 / 10 + this.easel.viewport.w / 6);
        const dy = Math.floor(y * this.easel.viewport.h / 3 * 2 / 10 + this.easel.viewport.h / 10);
        const type = Math.floor(this.list.length / 10);

        this.list.push(
          new Invader({
            easel: this.easel,
            id: this.list.length,
            type,
            dx,
            dy,
            color: this.colors[type],
            image: this.images[type]
          })
        );
      } // end for
    } // end for
  }

  getRandom () {
    return this.list[Math.floor(Math.random() * this.list.length)];
  }
}

/* eslint-disable no-invalid-this */
export function playerMovement () {
  const playerMovement = new this.Ion(this.easel);

  playerMovement.states = ['initial', 'started'];
  playerMovement.collection = [this.player];
  return playerMovement;
} // end playerMovement()

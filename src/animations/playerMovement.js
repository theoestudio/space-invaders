export function playerMovement(){
  console.log('player movement animation',this);
  const playerMovement = new Ion();

  playerMovement.states = ['initial','started'];
  playerMovement.collection = [player];
  playerMovement.onFinished = callback;
  return playerMovement;
} //end playerMovement()

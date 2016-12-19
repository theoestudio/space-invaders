import {Ion} from 'ion-cloud';
import {player} from '../player';

export function playerMovement(__this,callback){
  let playerMovement = new Ion();

  playerMovement.states = ['initial','started'];
  playerMovement.collection = [player];
  playerMovement.onFinished = callback;
  return playerMovement;
} //end playerMovement()

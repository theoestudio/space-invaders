import {Ion} from '../vendor/ion';
import {missiles} from '../missiles';

export function missileAttacks(){
  let missileAttacks = new Ion();

  missileAttacks.states = ['started'];
  missileAttacks.collection = missiles;
  return missileAttacks;
} //end missiles()


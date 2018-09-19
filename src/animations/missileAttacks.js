export function missileAttacks(){
  console.log('missile attacks animation',this);
  const missileAttacks = new Ion();

  missileAttacks.states = ['started'];
  missileAttacks.collection = missiles;
  return missileAttacks;
} //end missiles()


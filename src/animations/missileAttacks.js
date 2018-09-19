export function missileAttacks(){
  const missileAttacks = new this.Ion(this.easel);

  missileAttacks.states = ['started'];
  missileAttacks.collection = this.missiles.list;
  return missileAttacks;
} //end missiles()


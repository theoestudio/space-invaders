// Creates the entire matrix for the arcade character
export function generateInvader(){
  let a,b,c,
      r = (min,max)=> Math.floor(min+Math.random()*(1+max-min));

  return [
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a],
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a],
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a],
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a],
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a],
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a],
    [a=r(0,1),b=r(0,1),c=r(0,1),r(0,1),c,b,a]
  ];
} //end generateInvader()

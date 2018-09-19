import {Shield} from './Shield';

export function generateShields(easel){
  const shields = [
    new Shield(easel,1/4,easel.viewport.h-130),
    new Shield(easel,3/4,easel.viewport.h-130)
  ];

  if(easel.viewport.w>500){
    shields.push(new Shield(easel,1/2,easel.viewport.h-130));
  } //end if
  return shields;
}

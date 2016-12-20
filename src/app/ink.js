/**
 * Generically convert a hex to rgb using three-character format
 * ink('#fff')    //-------------------- outputs 'rgba(255,255,255,1)'
 *
 * Also supports full six-character format
 * ink('#ffffff') //-------------------- outputs 'rgba(255,255,255,1)'
 *
 * Give the converted rgb an alpha value
 * ink('#fff',0.5) //------------------- outputs 'rgba(255,255,255,0.5)'
 *
 * Apply modifiers to each color output
 * ink('#fff',{r:0.5,g:1,b:0.5}) //----- outputs 'rgba(127,255,127,1)'
 *
 * Supports adding an alpha to the modifier
 * ink('#fff',{r:0.6,g:1,b:0.5,a:0.5}) //outputs 'rgba(127,255,127,0.5)'
 *
 * Supports returning the value as an object for further manipulation
 * ink('#fff',{object:true}) /-----------outputs {r:255,g:255,b:255,o:1}
 *
 * Safely modifies values, preventing invalid values
 * ink('#3f3',{r:1.2,g:1.2,b:1.0}) //--- outputs 'rgba( 61,255, 51,1)'
 *
 * Modify each value and then require it to meet a lower threshold
 * for brightness. If it doesn't meet the lower threshold then it scales
 * all colors up to meet it
 * ink('#333',{r:1.2,g:1.2,b:1.2},0.3) //outputs 'rgba( 91, 91, 91,1)'
 *
 * Convert the color and give it both a lower and upper threshold for
 * brightness - note that it only alters color strengths if black was
 * given when threshold isn't met; otherwise, all zero-color factors
 * aren't scaled.
 * ink('#fff',1,0.3,0.8) //--------------outputs 'rgba(202,202,202,1)'
 * ink('#000',1,0.3,0.8) //--------------outputs 'rgba( 76, 76, 76,1)'
 * ink('#011',1,0.3,0.8) //--------------outputs 'rgba(114,114,114,1)'
 * ink('#248',1,0  ,0.3) //--------------outputs 'rgba( 32, 65,130,1)'
 */
export function ink(color,options,lowerboundThreshold,upperboundThreshold){
  let r,g,b, //color numbers 0-255
      result,
      isHex=color.includes('#'),
      isRgb=color.includes('rgb'),
      lowerbound = lowerboundThreshold||0.001,
      upperbound = upperboundThreshold||0.999,
      clt = ()=> !lowerbound || (r+g+b)/3/255 >= lowerbound,
      cut = ()=> !upperbound || (r+g+b)/3/255 <= upperbound,
      cot = ()=> { r=r>255?255:r;g=g>255?255:g;b=b>255?255:b; };

  // Begin by identifying the input color type and deciminating the r,g,b values
  if(isRgb){
    let splitRgb = color.split(/[,()]/g);

    r=splitRgb[1];g=splitRgb[2];b=splitRgbb[3];
  } //end if
  if(isHex){
    if(color.length===7){
      r = parseInt(color.substr(1,2),16);
      g = parseInt(color.substr(3,2),16);
      b = parseInt(color.substr(5,2),16);
    }else if(color.length===4){
      r = parseInt(color.substr(1,1)+color.substr(1,1),16);
      g = parseInt(color.substr(2,1)+color.substr(2,1),16);
      b = parseInt(color.substr(3,1)+color.substr(3,1),16);
    } //end if
  } //end if
  if(upperbound<lowerbound) [upperbound,lowerbound]=[lowerbound,upperbound];
  if(upperbound>=1) upperbound=0.999;
  if(lowerbound<=0) lowerbound=0.001;
  if(r===undefined||g===undefined||b===undefined){
    result = 'rgba(0,0,0,0)';
  }else{
    while(!clt()||!cut()){
      if(!clt()){  r*=1.1;g*=1.1;b*=1.1; }
      if(!cut()){ r*=0.9;g*=0.9;b*=0.9; }
    } //end while()
    cot();
    r=r|0;g=g|0;b=b|0; //float -> integer
    if(typeof options==='string'||typeof options==='number'){
      result = 'rgba('+r+','+g+','+b+','+options+')';
    }else if(typeof options==='object'){
      r=parseInt(r*(options.r||1),10);
      g=parseInt(g*(options.g||1),10);
      b=parseInt(b*(options.b||1),10);
      cot();
      if(options.object){
        result = {r:r,g:g,b:b,o:options.o||1};
      }else{
        result = `rgba(${r},${g},${b},${options.o||1})`;
      } //end if
    }else{
      result = 'rgba(0,0,0,0)';
    } //end if
  } //end if
  return result;
} //end ink()

// Convert rgb or rgba String to hex String
export function rgb2hex(rgb){
  let terms = rgb.split(/[,()]/g),
      r = parseInt(terms[1],10).toString(16),
      g = parseInt(terms[2],10).toString(16),
      b = parseInt(terms[3],10).toString(16);

  return `#${r}${g}${b}`;
} //end rgb2hex()

// generate a random hex color
export function randomHex(){
  let l = '0123456789abcdef'.split(''),
      c = '#';

  // r function is from easel library, generates random integer
  for(let i=0;i<6;i++) c+= l[r(15,0,true)];
  return c;
} //end randomHex()

// generate a random rgb, optionally pass expected alpha
export function randomRgb(alpha){
  let result,
      r = r(0,255,true),
      g = r(0,255,true),
      b = r(0,255,true);

  if(alpha){
    result = `rgba(${r},${g},${b},${alpha})`;
  }else{
    result = `rgb(${r},${g},${b})`;
  } //end if
  return result;
} //end randomRgb()

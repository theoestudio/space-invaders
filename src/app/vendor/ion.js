export class Ion{
  constructor(quantity,size,x1,y1,x2,y2){
    this.collection=[];
    this.clear=true;
    this.quantity=quantity||1;
    this.startX=x1||0;
    this.startY=y1||0;
    this.endX=x2||1;
    this.endY=y2||1;
    this.windX=0;
    this.windY=0;
    this.modulate=0; //only runs if it's set explicitly
    this.color='#48F';
    this.clearColor='#000';
    this.retain=null; //this can be set as a function for a draw after clear screen
    this.size=size||1;
    this.tweenType=0;
    this.tweenCurrent=0;
    this.tweenDuration=1000;
    this.tweenSpeed=1;
  }

  // Ease is a tweening function using Robert Penner's equations to identify
  // the values of an axis in respect to it's start location, destination,
  // and the normalization of the transition between the two with respect to
  // starting time, a given duration, and the function to impose upon the
  // transition from that start position to it's destination.
  ease(particle,axis){
    let result, //returns the current x or y location
        t = particle.tweenCurrent,
        d = particle.tweenDuration,
        o = 0.3, //modification orientation strength
        type = particle.tweenType,
        b,c; //beginning position and change in position

    if(axis==='x'){
      b = particle.startX;
      c = particle.endX-particle.startX;
    }else{
      b = particle.startY;
      c = particle.endY-particle.startY;
    } //end if
    if(type===0||type==='linear'){
      result = c*t/d+b;
    }else if(type===1||type==='ease-in-quad'){
      result = c*(t/=d)*t+b;
    }else if(type===2||type==='ease-out-quad'){
      result = -c*(t/=d)*(t-2)+b;
    }else if(type===3||type==='ease-in-out-quad'){
      result = (t/=d/2)<1?c/2*t*t+b:-c/2*((--t)*(t-2)-1)+b;
    }else if(type===4||type==='ease-in-cubic'){
      result = c*(t/=d)*t*t+b;
    }else if(type===5||type==='ease-out-cubic'){
      result = c*((t=t/d-1)*t*t+1)+b;
    }else if(type===6||type==='ease-in-out-cubic'){
      result = ((t/=d/2)<1)?c/2*t*t*t+b:c/2*((t-=2)*t*t+2)+b;
    }else if(type===7||type==='ease-in-quart'){
      result = c*(t/=d)*t*t*t+b;
    }else if(type===8||type==='ease-out-quart'){
      result = -c*((t=t/d-1)*t*t*t-1)+b;
    }else if(type===9||type==='ease-in-out-quart'){
      result = ((t/=d/2)<1)?c/2*t*t*t*t+b:-c/2*((t-=2)*t*t*t-2)+b;
    }else if(type===10||type==='ease-in-quint'){
      result = c*(t/=d)*t*t*t*t+b;
    }else if(type===11||type==='ease-out-quint'){
      result = c*((t=t/d-1)*t*t*t*t+1)+b;
    }else if(type===12||type==='ease-in-out-quint'){
      result = ((t/=d/2)<1)?c/2*t*t*t*t*t+b:c/2*((t-=2)*t*t*t*t+2)+b;
    }else if(type===13||type==='ease-in-sine'){
      result = -c*Math.cos(t/d*(Math.PI/2))+c+b;
    }else if(type===14||type==='ease-out-sine'){
      result = -c/2*(Math.cos(Math.PI*t/d)-1)+b;
    }else if(type===15||type==='ease-in-exponential'){
      result = (t===0)?b:c*Math.pow(2,10*(t/d-1))+b;
    }else if(type===16||type==='ease-out-exponential'){
      result = (t===d)?b+c:c*(-Math.pow(2,-10*t/d)+1)+b;
    }else if(type===17||type==='ease-in-out-exponential'){
      if(t===0){
        result = b;
      }else if(t===d){
        result = b+c;
      }else if((t/=d/2)<1){
        result = c/2*Math.pow(2,10*(t-1))+b;
      }else{
        result = c/2*(Math.pow(2,-10*--t)+2)+b;
      } //end if
    }else if(type===18||type==='ease-in-circular'){
      result = -c*(Math.sqrt(1-(t/=d)*t)-1)+b;
    }else if(type===19||type==='ease-out-circular'){
      result = c*Math.sqrt(1-(t=t/d-1)*t)+b;
    }else if(type===20||type==='ease-in-out-circular'){
      result = ((t/=d/2)<1)?-c/2*(Math.sqrt(1-t*t)-1)+b:c/2*(Math.sqrt(1-(t-=2)*t)+1)+b;
    }else if(type===21||type==='ease-in-elastic-loose'){
      result = this.ease(this,b,c,t,d,0.5,22);
    }else if(type===22||type==='ease-in-elastic-normal'){
      result = (()=>{
        var s=1.70158,p=0,a=c;

        if(t===0) return b;
        if((t/=d)===1) return b+c;
        if(!p) p=d*o;
        if(a < Math.abs(c+0.1)){
          a=c;s=p/4;
        }else{
          s = p/(2*Math.PI) * Math.asin(c/a);
        } //end if
        return -(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
      })();
    }else if(type===23||type==='ease-in-elastic-string'){
      result = this.ease(b,c,t,d,0.1,22);
    }else if(type===24||type==='ease-out-elastic-loose'){
      result = this.ease(b,c,t,d,0.5,25);
    }else if(type===25||type==='ease-out-elastic-normal'){
      result = (()=>{
        var s=1.70158,p=0,a=c;

        if (t===0) return b;
        if ((t/=d)===1) return b+c;
        if (!p) p=d*o;
        if(a < Math.abs(c+0.1)){
          a=c;s=p/4;
        }else{
          s = p/(2*Math.PI) * Math.asin(c/a);
        } //end if
        return a*Math.pow(2,-10*t) * Math.sin( (t*d-s)*(2*Math.PI)/p ) + c + b;
      })();
    }else if(type===26||type==='ease-out-elastic-strong'){
      result = this.ease(b,c,t,d,0.1,25);
    }else if(type===27||type==='ease-in-out-elastic-loose'){
      result = this.ease(b,c,t,d,0.5,28);
    }else if(type===28||type==='ease-in-out-elastic-normal'){
      result = (()=>{
        var s=1.70158,p=0,a=c;

        if(t===0) return b;
        if((t/=d/2)===2) return b+c;
        if(!p) p=d*(o*1.5);
        if(a < Math.abs(c+0.1)){
          a=c;s=p/4;
        }else{
          s = p/(2*Math.PI) * Math.asin(c/a);
        } //end if
        if (t < 1) return -0.5*(a*Math.pow(2,10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )) + b;
        return a*Math.pow(2,-10*(t-=1)) * Math.sin( (t*d-s)*(2*Math.PI)/p )*0.5 + c + b;
      })();
    }else if(type===29||type==='ease-in-out-elastic-strong'){
      result = this.ease(b,c,t,d,0.1,28);
    }else if(type===30||type==='ease-in-back'){
      result = c*(t/=d)*t*((1.70158+1)*t - 1.70158) + b;
    }else if(type===31||type==='ease-out-back'){
      result = c*((t=t/d-1)*t*((1.70158+1)*t + 1.70158) + 1) + b;
    }else if(type===32||type==='ease-in-out-back'){
      let s = 1.70158;

      if((t/=d/2)<1){
        result = c/2*(t*t*(((s*=(1.525))+1)*t - s)) + b;
      }else{
        result = c/2*((t-=2)*t*(((s*=(1.525))+1)*t + s) + 2) + b;
      } //end if
    }else if(type===33||type==='ease-in-bounce'){
      result = c-this.ease(0,c,d-t,d,0,34)+b;
    }else if(type===34||type==='ease-out-bounce'){
      if ((t/=d) < (1/2.75)) {
        result = c*(7.5625*t*t) + b;
      } else if (t < (2/2.75)) {
        result = c*(7.5625*(t-=(1.5/2.75))*t + 0.75) + b;
      } else if (t < (2.5/2.75)) {
        result = c*(7.5625*(t-=(2.25/2.75))*t + 0.9375) + b;
      } else {
        result = c*(7.5625*(t-=(2.625/2.75))*t + 0.984375) + b;
      } //end if
    }else if(type===35||type==='ease-in-out-bounce'){
      if(t<d/2){
        result = this.ease(0,c,t*2,d,0,33)*0.5+b;
      }else{
        result = this.ease(0,c,t*2-d,d,0,34)*0.5+c*0.5+b;
      } //end if
    }//end if
    return result;
  } //end Ion.ease()

  // getNew will create a new particle and return that result. It's possible to override the
  // function to develop a custom particle generator for more specific applications.
  getNew(id){
    var ttc = this.tweenCurrent,
        ttd = this.tweenDuration,
        ttt = this.tweenType,
        tsx = this.startX,
        tsy = this.startY,
        tdx = this.endX,
        tdy = this.endY,
        sx = typeof tsx==='function'?tsx():tsx,
        sy = typeof tsy==='function'?tsy():tsy,
        dx = typeof tdx==='function'?tdx():tdx,
        dy = typeof tdy==='function'?tdy():tdy,
        c = typeof ttc==='function'?ttc():ttc,
        d = typeof ttd==='function'?ttd():ttd,
        tt = typeof ttt==='function'?ttt():ttt,
        s = typeof this.size==='function'?this.size():this.size,
        image = typeof this.image==='function'?this.image():this.image,
        particle = {};

    this.onCreate(); //even fired as a new particle is created
    particle.id = id; //for referencing each particle outside library
    particle.startX = sx;
    particle.startY = sy;
    particle.originX = particle.startX;
    particle.originY = particle.startY;
    particle.x = sx;
    particle.y = sy;
    particle.endX = dx;
    particle.endY = dy;
    particle.terminalX = particle.endX; //original destiation x
    particle.terminalY = particle.endY; //original destination y
    particle.tweenCurrent = c;
    particle.tweenDuration = d;
    particle.tweenType = tt;
    particle.size = s; //the particle size
    particle.windX = this.windX||0; //wind functions are ran at runtime
    particle.windY = this.windY||0; //wind function are ran at runtime
    particle.image = image; //can be an image or a draw function
    particle.imageWidth = this.imageWidth; //width in pixels
    particle.imageHeight = this.imageHeight; //height in pixels
    return particle;
  } //end Ion.getNew()

  // Reset will perform a small number of operations to reset a particle back
  // to a starting state instead of actually generating a new particle. This
  // can be helpful if you want to retain it's current location or properties
  // that have been computed thus far. It's further helpful because it can be
  // overridden to perform other operations post-completion of the particles
  // duration.
  reset(particle){
    particle.x = particle.startX = particle.originX;
    particle.y = particle.startY = particle.originY;
    particle.endX = particle.terminalX; //wind may have corrupted endX
    particle.endY = particle.terminalY; //wind may have corrupted endY
    particle.tweenCurrent = 0;
  } //end Ion.reset()

  // Populate pushes a new particle into the particles array then checks to see
  // if the specified particle number has been reached, if it hasn't, then it
  // queues up itself asynchronously to create another particle. This recursive
  // action continues until the total particle quantity is reached.
  populate(wait){
    this.collection.push(this.getNew(this.collection.length));
    if(this.collection.length<this.quantity){
      if(typeof wait === 'function'){
        setTimeout(()=> this.populate(wait),wait());
      }else{
        requestAnimationFrame(()=> this.populate());
      } //end if
    } //end if
  } //end Ion.populate()

  // Wind applies noise values on the movement patterns of the particles
  // instead of them performing their tweening operations unhindered. This
  // gives a more dynamic feel to their movement. The wind patterns and
  // function can be overridden to be dynamic or conditional as desired.
  wind(particle){
    if(typeof particle.windX === 'function'){
      particle.endX += particle.windX(particle);
    }else{
      particle.endX += particle.windX;
    } //end if
    if(typeof particle.windY === 'function'){
      particle.endY += particle.windY(particle);
    }else{
      particle.endY += particle.windY;
    } //end if
    if(typeof particle.windX === 'function'){
      particle.startX += particle.windX(particle);
    }else{
      particle.startX += particle.windX;
    } //end if
    if(typeof particle.windX === 'function'){
      particle.startY += particle.windY(particle);
    }else{
      particle.startY += particle.windY;
    } //end if
  } //end Ion.wind()

  // Draw simply draws a particle indicated by its index number
  draw(particle){
    let p = particle,
        image = p.image,
        s = p.size;

    if(image && image instanceof Array && image.length){
      let scaleX = p.imageWidth/image[0].length,
          scaleY = p.imageHeight/image.length;

      image.forEach((yo,y)=>{
        yo.forEach((xo,x)=>{
          if(xo) ctx.fillRect(p.x+x*scaleX,p.y+y*scaleY,s*scaleX,s*scaleY);
        });
      });
    }else if(image){ //image was passed, use it instead of a pixel particle
      let px = p.x-p.imageWidth/2,
          py = p.y-p.imageHeight/2;

      if(p.imageWidth && p.imageHeight){ //sizes given for constrain
        ctx.drawImage(image,px,py,p.imageWidth,p.imageHeight);
      }else{ //no sizes given, just allow it to fill with images normal size
        ctx.drawImage(image,px,py);
      } //end if
    }else{
      ctx.fillRect(p.x,p.y,s,s);
    } //end if
  } //end Ion.draw()

  // OnCreate function is called when a particle is created for the first
  // time. This allows one to keep track of how far into the creation of all
  // the particles one is given the particle total that they already control.
  onCreate(){}

  // OnEnd function is called after a particle finishes its tweening motion.
  // This is merely a template function that is required to be overridden.
  onEnd(){}

  // OnEscape function is called after a particle leaves the view space.
  // This is merely a template function that is required to be overridden.
  onEscape(){}

  // Process is the automatic function that calls the getFrame main
  // function and after updating, queues the next update frame. It will
  // also auto-clear. This function is mostly used for testing a single
  // Ion instance. Most mock-ups of Ion should be done using the getFrame
  // function and manually resetting the canvas as needed
  process(){
    if(typeof this.clear === 'function'){ //override clear function, use it instead
      this.clear();
    } else if(this.clear){ //sent as some truthy value, likely boolean true
      ctx.fillStyle=this.clearColor;
      ctx.fillRect(0,0,v.w,v.h);
    } //end if
    if(this.clear && this.retain){
      this.retain(); //if there is a retaining script, run it
    } //end if
    this.getFrame(); //call getFrame() to receive and flip all pixel information for next update
    if(this.tweenSpeed===1){
      requestAnimationFrame(()=>this.process());
    }else{
      setTimeout(()=>this.process(),this.tweenSpeed);
    } //end if
  } //end Ion.process()

  // getFrame is the main function that performs operations on each particle.
  // It immediately flips those variables after they've been computed. There
  // is no clearing of pixels, it superimposes onto what's already available
  // on the screen so any clearing will have to be done through the process
  // function or manually.
  getFrame(){
    ctx.fillStyle=this.color;
    this.collection.forEach(p=>{
      this.wind(p);
      this.draw(p);
      if(typeof this.modulate ==='function') this.modulate(p);
      if(p.x<0||p.y<0||p.x>v.w||p.y>v.h)this.onEscape(p);
      p.tweenCurrent++;
      if(p.tweenCurrent===p.tweenDuration)this.onEnd(p);
      if((p.x|0)!==(p.dx|0)) p.x=this.ease(p,'x');
      if((p.y|0)!==(p.dy|0)) p.y=this.ease(p,'y');
    });
  } //end Ion.getFrame()
} //end class Ion
export default {Ion};

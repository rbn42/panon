#version 130


float DistToLine(vec2 pt1, vec2 pt2, vec2 testPt) {
    vec2 lineDir = pt2 - pt1;
    vec2 perpDir = vec2(lineDir.y, -lineDir.x);
    vec2 dirToPt1 = pt1 - testPt;
    return abs(dot(normalize(perpDir), dirToPt1));
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor=vec4(0,0,0,0);
    int width=20;
    float speed=-2;
    float offset_=iTime*speed;

    float x=fragCoord.x/width ;
    float a=floor(x+fract(offset_))-fract(offset_);
    float b=fract(x+offset_);

    ivec2 p1=ivec2((a+0)*width,0); //
    ivec2 p2=ivec2((a+.5)*width,0);//(.5-.5*sample_.g ) *iResolution.y);
    ivec2 p3=ivec2((a+1)*width,0); //(.5+.5*sample_.r ) *iResolution.y);
    p1.y= int(iResolution.y*(texture(iChannel1, vec2(p1.x/iResolution.x,0)).r *.5+.5));
    p2.y= int(iResolution.y*(texture(iChannel1, vec2(p2.x/iResolution.x,0)).g *-.5+.5));
    p3.y= int(iResolution.y*(texture(iChannel1, vec2(p3.x/iResolution.x,0)).r *.5+.5));
    p1.y=int(max(iResolution.y/2,p1.y-2));
    p2.y=int(min(iResolution.y/2,p2.y+2));
    p3.y=int(max(iResolution.y/2,p3.y-2));

    bool draw=false;
        if(b<.5)
    if(DistToLine(p1,p2,fragCoord)<1.0) {
            draw=true;
    }
        if(b>.5)
    if(DistToLine(p2,p3,fragCoord)<1.0) {
            draw=true;
    }

    if (draw) {
        fragColor.rgb=getRGB((fragCoord.x-offset_*width)/iResolution.x);
        fragColor.a=1;
    }
}

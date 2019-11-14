#version 130

/*
 * Inspired by OieIcons
 * https://store.kde.org/p/1299058/
 */

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec4 sample_prev= texture(iChannel1, vec2((fragCoord.x-1)/iResolution.x,0)) ;
    vec4 sample_    = texture(iChannel1, vec2(fragCoord.x  /iResolution.x,0)) ;
    vec4 sample_next= texture(iChannel1, vec2((fragCoord.x+1)/iResolution.x,0)) ;

    int p1=int(1/2.*(sample_.r+sample_prev.r) * iResolution.y);
    int p2=int(1/2.*(sample_.r+sample_next.r) * iResolution.y);

    fragColor=vec4(0,0,0,0);

    bool draw=false;
    if(p1+1>=fragCoord.y&&fragCoord.y>=p2-1)draw=true;
    if(p1-1<=fragCoord.y&&fragCoord.y<=p2+1)draw=true;


    if(draw) {
        fragColor.rgb=getRGB(fragCoord.x/iResolution.x);
        fragColor.a=1;
    }
}

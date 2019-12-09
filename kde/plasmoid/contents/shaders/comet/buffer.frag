#version 130

#define volume_threshold $volume_threshold

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    vec4 newspec= texture(iChannel1,vec2(fragCoord.y/iResolution.y,0));

    if(fragCoord.x<1) {
        fragColor= newspec;
        return;
    }

    vec4 oldspec= texelFetch(iChannel2,ivec2(0,fragCoord.y), 0);
    vec4 diff=newspec-oldspec-volume_threshold;

    if( fragCoord.x<2) {
        fragColor=diff;
        return;
    }

    fragColor= texelFetch(iChannel2,ivec2(fragCoord.x-1,fragCoord.y), 0);
}

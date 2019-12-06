#version 130

#define transparent $transparent 

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor= texelFetch(iChannel2,ivec2(fragCoord) , 0);
    fragColor.a=transparent?max(fragColor.r,fragColor.g):1;
}

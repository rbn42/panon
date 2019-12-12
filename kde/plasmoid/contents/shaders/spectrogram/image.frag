#version 130

#define opacity $opacity

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor= texelFetch(iChannel2,ivec2(fragCoord) , 0);
    fragColor.a=opacity+ max(fragColor.r,fragColor.g);
}

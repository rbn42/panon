#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor= texelFetch(iChannel2,ivec2(fragCoord) , 0);
    fragColor.a=1;
}

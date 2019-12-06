#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor= texelFetch(iChannel2,ivec2(fragCoord.x/2+iResolution.x/2,fragCoord.y) , 0);
    fragColor.a=1;
}

#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor= texelFetch(iChannel2,ivec2(fragCoord.x,fragCoord.y-1) , 0);
    if(fragCoord.y<1){
        float x=fragCoord.x/iResolution.x;
        fragColor= texture(iChannel1, vec2(x,0));
    }
}

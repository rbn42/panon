#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragColor=vec4(0.001,0.001,0.001,0.001);
    if(distance(iMouse.xy,fragCoord)<30)
        fragColor=vec4(1,1,0,1);
}

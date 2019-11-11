#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    float x=fragCoord.x/iResolution.x;

    vec4 sample1= texture(iChannel1, vec2(x,0)) ;
    vec3 rgb=getRGB(x);

    float a=(sample1.r+sample1.g)/2.0;
    fragColor=vec4(rgb*a,a);
}

#version 130

float height(float distanc,float raw_height) {
    return raw_height*exp(-distanc*distanc*4);
}

float rand(vec2 co) {
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord=fragCoord/iResolution.xy;
    float px_step=0.0000315;
    int max_distance=1280;

    float h=fragCoord.y;

    fragColor=vec4(0,0,0,0);
    for(int j=0; j<60; j++) {
        int i=int((2*max_distance+1)*rand(fragCoord+vec2(iTime/60/60/24/10,j)))-max_distance;
        float distanc=abs(i)/1.0/max_distance;
        float x=int(fragCoord.x/px_step+i)*px_step;

        vec4 raw=texture(iChannel1, vec2(x,0));
        float raw_max=(raw.g+raw.r)/2.;
        float h_target=height(distanc,raw_max);
        if(h_target-.02<=h && h<=h_target) {
            fragColor=vec4(getRGB(5*x),1.);
            break;
        }
    }
}

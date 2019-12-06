#version 130

#define particle_opacity $particle_opacity
#define height_ratio $height_ratio
#define strength $strength
#define unit_radius $unit_radius
#define density $density



float rand(vec2 co) {
    return fract(sin(dot(co.xy,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {

    float h=fragCoord.y/iResolution.y;
    bool gr=(h>.5);
    h=abs(2*h-1);
    h+=0.01;

    fragColor=vec4(0,0,0,0);
    for(int j=0; j<density; j++) {
        float num=rand(fragCoord/iResolution.xy+vec2(iTime/60/60/24/10,j));
        float distanc=(2*num-1);
        float i=(2*num-1)*unit_radius/sqrt(strength);
        float x=fragCoord.x+i;

        vec4 raw=texture(iChannel1, vec2(x/iResolution.x,0));
        float raw_max=gr?raw.g:raw.r;
        float h_target1=height_ratio* raw_max*exp(-distanc*distanc/strength)*iResolution.y-.03*iResolution.y*height_ratio;
        float h_target2=height_ratio* raw_max*exp(-distanc*distanc/strength)*iResolution.y;

        if(h_target1<=h*iResolution.y)
            if(h*iResolution.y<=h_target2) {
            fragColor+=vec4(getRGB(5*x/iResolution.x)*particle_opacity ,particle_opacity );
        }
    }
}

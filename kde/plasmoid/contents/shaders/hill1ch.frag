#version 130

float height(float distanc,float raw_height) {
    return raw_height*exp(-distanc*distanc*3);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord=fragCoord/iResolution.xy;
    float px_step=0.0005;
    int max_distance=40;

    float h=fragCoord.y;

    fragColor=vec4(0,0,0,0);
    float max_nb=0;
    for(int i=-max_distance; i<max_distance+1; i++) {
        float distanc=abs(i)/1.0/max_distance;
        float x=fragCoord.x+i*px_step;
        x=int(x*2000)/2000.0;

        vec4 raw=texture(iChannel1, vec2(x,1/8.));
        float raw_max=(raw.g+raw.r)/2.;

        if(h <=height(distanc,raw_max))
            if(raw_max>max_nb) {
                max_nb=raw_max;
                fragColor=vec4(getRGB(5*x),1.);
            }
    }
}

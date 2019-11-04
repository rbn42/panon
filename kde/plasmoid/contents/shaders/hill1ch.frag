#version 130
uniform sampler2D tex1;
out vec4 out_Color;

float height1(float distanc,float raw_height) {
    return raw_height-distanc;
}

float height2(float distanc,float raw_height) {
    return raw_height/(1+distanc*distanc);
}

float height(float distanc,float raw_height) {
    return raw_height*exp(-distanc*distanc*3);
}

void main()
{
    float px_step=0.0005;
    int max_distance=40;

    float h=1-getCoord().y;

    out_Color=vec4(0,0,0,0);
    float max_nb=0;
    for(int i=-max_distance; i<max_distance+1; i++) {
        float distanc=abs(i)/1.0/max_distance;
        float x=getCoord().x+i*px_step;
        x=int(x*2000)/2000.0;

        vec4 raw=texture(tex1, vec2(x,1/8.));
        float raw_max=(raw.g+raw.r)/2.;

        if(h <=height(distanc,raw_max))
            if(raw_max>max_nb) {
                max_nb=raw_max;
                out_Color=vec4(getRGB(5*x),1.);
            }
    }
}

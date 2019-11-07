#version 130

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    fragCoord=fragCoord/iResolution.xy;
    vec4 sample1= texture(iChannel1, vec2(fragCoord.x,1/8.)) ;
    float h=fragCoord.y;
    vec3 rgb=getRGB(fragCoord.x);

    float[] rels=float[5](4.,3.,2.,1.,.5);
    float[] alphas=float[5](.1,.2,.3,.5,1.);
    //float[] rels=float[1](1.0);
    //float[] alphas=float[1](1.0);
    fragColor=vec4(0.001,0.001,0.001,0.001);
    for (int i=0; i<5; i++) {
        float r=rels[i];
        float a=alphas[i];
        float max_=.5+sample1.r*r;
        float min_=.5-sample1.g*r;
        if(min_<=h && h <=max_)
            fragColor=vec4(rgb*a,a);
    }
}

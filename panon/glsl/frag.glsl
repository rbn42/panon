#version 400
uniform sampler2D tex1;
in vec2 v_position;
out vec4 out_Color;


vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    vec4 sample1= texture(tex1, vec2(v_position.x/2,0.5));
    vec4 sample2= texture(tex1, vec2(1-v_position.x/2,0.5));
    float h=v_position.y;

    float[] rels=float[5](4.,3.,2.,1.,.5);
    float[] alphas=float[5](.1,.2,.3,.5,1.);
    vec3 hsv=vec3(v_position.x*1.5+0.5,1,1);
    vec3 rgb=hsv2rgb(hsv);
    out_Color=vec4(0,0,0,0.0);
    for (int i=0; i<5; i++) {
        float r=rels[i];
        float a=alphas[i];
        float min_=.5-sample1.r*r;
        float max_=.5+sample2.r*r;
        if(min_<=h && h <=max_)
            out_Color=vec4(rgb*a,a);
    }
}

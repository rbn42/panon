#version 130

#define pixel_fill $bar_width
#define pixel_empty $gap_width

vec4 mean(float _from,float _to) {

    if(_from>1.0)
        return vec4(0);

    _from=iChannelResolution[1].x*_from;
    _to=iChannelResolution[1].x*_to;

    vec4 v=texelFetch(iChannel1, ivec2(_from,0),0) * (1.0-fract(_from)) ;

    for(float i=ceil(_from); i<floor(_to); i++)
        v+=texelFetch(iChannel1, ivec2(i,0),0) ;

    if(floor(_to)>floor(_from))
        v+=texelFetch(iChannel1,ivec2(_to,0),0)* fract(_to);
    else
        v-=texelFetch(iChannel1,ivec2(_to,0),0)*(1.0- fract(_to));

    return v/(_to-_from);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
    int pixel_x= int( fragCoord.x);
    int pixel_y= int( fragCoord.y);

    float h=fragCoord.y/iResolution.y;


    fragColor=vec4(0,0,0,0);
    if(pixel_x%(pixel_fill+pixel_empty)<pixel_fill) {

        float id=floor(fragCoord.x/(pixel_fill+pixel_empty));
        vec4 sample1=mean(id*(pixel_fill+pixel_empty)/iResolution.x,
                          (1+id)*(pixel_fill+pixel_empty)/iResolution.x);

        float x=pixel_x/(pixel_fill+pixel_empty) /1.0/iResolution.x*(pixel_fill+pixel_empty) ;
        vec3 rgb=getRGB(x);

        //vec4 sample1= texture(iChannel1, vec2(x,0)) ;
        float max_=sample1.g*.5+sample1.r*.5;
        if(h<=max_)
            fragColor=vec4(rgb*1.,1.);

        vec4 sample2= texelFetch(iChannel2,ivec2(id,0) , 0);
        int max_2=int(iResolution.y*(sample2.g+sample2.r)/2);
        if((max_2-1)<pixel_y && pixel_y <max_2+1)
            fragColor=vec4(rgb*1.,1.);
    }
}

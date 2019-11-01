#version 130
uniform sampler2D tex1;
in mediump vec2 qt_TexCoord0;
out vec4 out_Color;
uniform int canvas_width;
uniform int canvas_height;

void main()
{
    int pixel_x=int(qt_TexCoord0.x*canvas_width);

    int pixel_fill=5;
    int pixel_empty=2;

    float h=1-qt_TexCoord0.y;
    int pixel_y=int(h*canvas_height);

    out_Color=vec4(0,0,0,0);
    if(pixel_x%(pixel_fill+pixel_empty)<pixel_fill){
        float x=pixel_x/(pixel_fill+pixel_empty) /1.0/canvas_width*(pixel_fill+pixel_empty) ;
        vec3 rgb=getRGB(x);

        vec4 sample1= texture(tex1, vec2(x,1/8.)) ;
        float max_=sample1.g*.5+sample1.r*.5;
        if(h<=max_)
            out_Color=vec4(rgb*1.,1.);

        vec4 sample2= texture(tex1, vec2(x,3/8.)) ;
        int max_2=int(canvas_height*(sample2.g+sample2.r)/2);
        if((max_2-1)<pixel_y && pixel_y <max_2+1)
            out_Color=vec4(rgb*1.,1.);
    }
}

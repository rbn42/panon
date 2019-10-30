uniform sampler2D tex1;

uniform bool colorSpaceHSL;
uniform bool colorSpaceHSLuv;
uniform int hslHueFrom;
uniform int hslHueTo;
uniform int hsluvHueFrom;
uniform int hsluvHueTo;
uniform int hslSaturation;
uniform int hslLightness;
uniform int hsluvSaturation;
uniform int hsluvLightness;

in mediump vec2 qt_TexCoord0;
out vec4 out_Color;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 getRGB(float x){
    if(colorSpaceHSL){
        return hsv2rgb(vec3(x*(hslHueTo-hslHueFrom)/360.0+hslHueFrom/360.0,hslSaturation/100.0,hslLightness/100.0));
    }else if(colorSpaceHSLuv){
        return huslToRgb(vec3(x*(hsluvHueTo-hsluvHueFrom)+hsluvHueFrom,hsluvSaturation,hsluvLightness));
    }
}

void main()
{
    vec4 sample1= texture(tex1, vec2(qt_TexCoord0.x,0.5)) ;
    float h=qt_TexCoord0.y;

    vec3 rgb=getRGB(qt_TexCoord0.x);
    out_Color=vec4(0.001,0.001,0.001,0.001);
    float r=0.5;
    float a=1.;
    float max_=.5+sample1.r*r;
    float min_=.5-sample1.g*r;
    if(min_<=h && h <=max_)
        out_Color=vec4(rgb*a,a);
}

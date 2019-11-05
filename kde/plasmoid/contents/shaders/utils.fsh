// vim: set ft=glsl:
uniform bool colorSpaceHSL;
uniform bool colorSpaceHSLuv;
uniform int hueFrom;
uniform int hueTo;
uniform int saturation;
uniform int lightness;

in mediump vec2 qt_TexCoord0;

// gravity property: North (1), West (4), East (3), South (2)
uniform int gravity;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 getRGB(float x){
    if(colorSpaceHSL){
        return hsv2rgb(vec3(x*(hueTo-hueFrom)/360.0+hueFrom/360.0,saturation/100.0,lightness/100.0));
    }else if(colorSpaceHSLuv){
        return huslToRgb(vec3(x*(hueTo-hueFrom)+hueFrom,saturation,lightness));
    }
}

vec2 getCoord(){
    switch(gravity){
        case 1:
        return qt_TexCoord0;
        case 2:
        return vec2(qt_TexCoord0.x,1-qt_TexCoord0.y);
        case 3:
        return vec2(1-qt_TexCoord0.y,qt_TexCoord0.x);
        case 4:
        return vec2(1-qt_TexCoord0.y,1-qt_TexCoord0.x);
    }
}

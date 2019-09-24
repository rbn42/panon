
import QtQuick 2.0
import QtWebSockets 1.0
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0

Item{
    Layout.preferredWidth: plasmoid.configuration.preferredWidth
    Layout.fillWidth:plasmoid.configuration.autoExtend 

    ShaderEffect {
        property bool colorSpaceHSL:plasmoid.configuration.colorSpaceHSL
        property bool colorSpaceHSLuv:plasmoid.configuration.colorSpaceHSLuv

        property int hslHueFrom    :plasmoid.configuration.hslHueFrom
        property int hslHueTo    :plasmoid.configuration.hslHueTo
        property int hsluvHueFrom  :plasmoid.configuration.hsluvHueFrom
        property int hsluvHueTo  :plasmoid.configuration.hsluvHueTo
        property int hslSaturation  :plasmoid.configuration.hslSaturation
        property int hslLightness   :plasmoid.configuration.hslLightness
        property int hsluvSaturation:plasmoid.configuration.hsluvSaturation
        property int hsluvLightness :plasmoid.configuration.hsluvLightness

        property variant tex1:messageBox
        anchors.fill: parent
        blending: true
        fragmentShader: "#version 400
        /*
HUSL-GLSL v3.2
HUSL is a human-friendly alternative to HSL. ( http://www.husl-colors.org )
GLSL port by William Malo ( https://github.com/williammalo )
Put this code in your fragment shader.
*/

vec3 husl_intersectLineLine(vec3 line1x, vec3 line1y, vec3 line2x, vec3 line2y) {
    return (line1y - line2y) / (line2x - line1x);
}

vec3 husl_distanceFromPole(vec3 pointx,vec3 pointy) {
    return sqrt(pointx*pointx + pointy*pointy);
}

vec3 husl_lengthOfRayUntilIntersect(float theta, vec3 x, vec3 y) {
    vec3 len = y / (sin(theta) - x * cos(theta));
    if (len.r < 0.0) {len.r=1000.0;}
    if (len.g < 0.0) {len.g=1000.0;}
    if (len.b < 0.0) {len.b=1000.0;}
    return len;
}

float husl_maxSafeChromaForL(float L){
    mat3 m2 = mat3(
        vec3( 3.2409699419045214  ,-0.96924363628087983 , 0.055630079696993609),
        vec3(-1.5373831775700935  , 1.8759675015077207  ,-0.20397695888897657 ),
        vec3(-0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  )
    );
    float sub1 = pow(L + 16.0, 3.0) / 1560896.0;
    float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;

    vec3 top1   = (284517.0 * m2[0] - 94839.0  * m2[2]) * sub2;
    vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;
    vec3 top2   = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;

    vec3 bounds0x = top1 / bottom;
    vec3 bounds0y = top2 / bottom;

    vec3 bounds1x =              top1 / (bottom+126452.0);
    vec3 bounds1y = (top2-769860.0*L) / (bottom+126452.0);

    vec3 xs0 = husl_intersectLineLine(bounds0x, bounds0y, -1.0/bounds0x, vec3(0.0) );
    vec3 xs1 = husl_intersectLineLine(bounds1x, bounds1y, -1.0/bounds1x, vec3(0.0) );

    vec3 lengths0 = husl_distanceFromPole( xs0, bounds0y + xs0 * bounds0x );
    vec3 lengths1 = husl_distanceFromPole( xs1, bounds1y + xs1 * bounds1x );

    return  min(lengths0.r,
            min(lengths1.r,
            min(lengths0.g,
            min(lengths1.g,
            min(lengths0.b,
                lengths1.b)))));
}

float husl_maxChromaForLH(float L, float H) {

    float hrad = radians(H);

    mat3 m2 = mat3(
        vec3( 3.2409699419045214  ,-0.96924363628087983 , 0.055630079696993609),
        vec3(-1.5373831775700935  , 1.8759675015077207  ,-0.20397695888897657 ),
        vec3(-0.49861076029300328 , 0.041555057407175613, 1.0569715142428786  )
    );
    float sub1 = pow(L + 16.0, 3.0) / 1560896.0;
    float sub2 = sub1 > 0.0088564516790356308 ? sub1 : L / 903.2962962962963;

    vec3 top1   = (284517.0 * m2[0] - 94839.0  * m2[2]) * sub2;
    vec3 bottom = (632260.0 * m2[2] - 126452.0 * m2[1]) * sub2;
    vec3 top2   = (838422.0 * m2[2] + 769860.0 * m2[1] + 731718.0 * m2[0]) * L * sub2;

    vec3 bound0x = top1 / bottom;
    vec3 bound0y = top2 / bottom;

    vec3 bound1x =              top1 / (bottom+126452.0);
    vec3 bound1y = (top2-769860.0*L) / (bottom+126452.0);

    vec3 lengths0 = husl_lengthOfRayUntilIntersect(hrad, bound0x, bound0y );
    vec3 lengths1 = husl_lengthOfRayUntilIntersect(hrad, bound1x, bound1y );

    return  min(lengths0.r,
            min(lengths1.r,
            min(lengths0.g,
            min(lengths1.g,
            min(lengths0.b,
                lengths1.b)))));
}

float husl_fromLinear(float c) {
    return c <= 0.0031308 ? 12.92 * c : 1.055 * pow(c, 1.0 / 2.4) - 0.055;
}

float husl_toLinear(float c) {
    return c > 0.04045 ? pow((c + 0.055) / (1.0 + 0.055), 2.4) : c / 12.92;
}

vec3 husl_toLinear(vec3 c) {
    return vec3( husl_toLinear(c.r), husl_toLinear(c.g), husl_toLinear(c.b) );
}

float husl_yToL(float Y){
    return Y <= 0.0088564516790356308 ? Y * 903.2962962962963 : 116.0 * pow(Y, 1.0 / 3.0) - 16.0;
}

float husl_lToY(float L) {
    return L <= 8.0 ? L / 903.2962962962963 : pow((L + 16.0) / 116.0, 3.0);
}

vec3 xyzToRgb(vec3 tuple) {
    return vec3(
        husl_fromLinear(dot(vec3( 3.2409699419045214  ,-1.5373831775700935 ,-0.49861076029300328 ), tuple.rgb )),//r
        husl_fromLinear(dot(vec3(-0.96924363628087983 , 1.8759675015077207 , 0.041555057407175613), tuple.rgb )),//g
        husl_fromLinear(dot(vec3( 0.055630079696993609,-0.20397695888897657, 1.0569715142428786  ), tuple.rgb )) //b
    );
}

vec3 rgbToXyz(vec3 tuple) {
    vec3 rgbl = husl_toLinear(tuple);
    return vec3(
        dot(vec3(0.41239079926595948 , 0.35758433938387796, 0.18048078840183429 ), rgbl ),//x
        dot(vec3(0.21263900587151036 , 0.71516867876775593, 0.072192315360733715), rgbl ),//y
        dot(vec3(0.019330818715591851, 0.11919477979462599, 0.95053215224966058 ), rgbl ) //z
    );
}

vec3 xyzToLuv(vec3 tuple){
    float X = tuple.x;
    float Y = tuple.y;
    float Z = tuple.z;

    float L = husl_yToL(Y);

    return vec3(
        L,
        13.0 * L * ( (4.0 * X) / (X + (15.0 * Y) + (3.0 * Z)) - 0.19783000664283681),
        13.0 * L * ( (9.0 * Y) / (X + (15.0 * Y) + (3.0 * Z)) - 0.468319994938791  )
    );
}

vec3 luvToXyz(vec3 tuple) {
    float L = tuple.x;

    float varU = tuple.y / (13.0 * L) + 0.19783000664283681;
    float varV = tuple.z / (13.0 * L) + 0.468319994938791;

    float Y = husl_lToY(L);
    float X = 0.0 - (9.0 * Y * varU) / ((varU - 4.0) * varV - varU * varV);
    float Z = (9.0 * Y - (15.0 * varV * Y) - (varV * X)) / (3.0 * varV);

    return vec3(X, Y, Z);
}

vec3 luvToLch(vec3 tuple) {
    float L = tuple.x;
    float U = tuple.y;
    float V = tuple.z;

    float C = sqrt(pow(U, 2.0) + pow(V, 2.0));
    float H = degrees(atan(V, U));
    if (H < 0.0) {
        H = 360.0 + H;
    }
    
    return vec3(L, C, H);
}

vec3 lchToLuv(vec3 tuple) {
    float hrad = radians(tuple.b);
    return vec3(
        tuple.r,
        cos(hrad) * tuple.g,
        sin(hrad) * tuple.g
    );
}

vec3 huslToLch(vec3 tuple) {
    tuple.g *= husl_maxChromaForLH(tuple.b, tuple.r) / 100.0;
    return tuple.bgr;
}

vec3 lchToHusl(vec3 tuple) {
    tuple.g /= husl_maxChromaForLH(tuple.r, tuple.b) * 100.0;
    return tuple.bgr;
}

vec3 huslpToLch(vec3 tuple) {
    tuple.g *= husl_maxSafeChromaForL(tuple.b) / 100.0;
    return tuple.bgr;
}

vec3 lchToHuslp(vec3 tuple) {
    tuple.g /= husl_maxSafeChromaForL(tuple.r) * 100.0;
    return tuple.bgr;
}

vec3 lchToRgb(vec3 tuple) {
    return xyzToRgb(luvToXyz(lchToLuv(tuple)));
}

vec3 rgbToLch(vec3 tuple) {
    return luvToLch(xyzToLuv(rgbToXyz(tuple)));
}

vec3 huslToRgb(vec3 tuple) {
    return lchToRgb(huslToLch(tuple));
}

vec3 rgbToHusl(vec3 tuple) {
    return lchToHusl(rgbToLch(tuple));
}

vec3 huslpToRgb(vec3 tuple) {
    return lchToRgb(huslpToLch(tuple));
}

vec3 rgbToHuslp(vec3 tuple) {
    return lchToHuslp(rgbToLch(tuple));
}

vec3 luvToRgb(vec3 tuple){
    return xyzToRgb(luvToXyz(tuple));
}

// allow vec4's
vec4   xyzToRgb(vec4 c) {return vec4(   xyzToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4   rgbToXyz(vec4 c) {return vec4(   rgbToXyz( vec3(c.x,c.y,c.z) ), c.a);}
vec4   xyzToLuv(vec4 c) {return vec4(   xyzToLuv( vec3(c.x,c.y,c.z) ), c.a);}
vec4   luvToXyz(vec4 c) {return vec4(   luvToXyz( vec3(c.x,c.y,c.z) ), c.a);}
vec4   luvToLch(vec4 c) {return vec4(   luvToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4   lchToLuv(vec4 c) {return vec4(   lchToLuv( vec3(c.x,c.y,c.z) ), c.a);}
vec4  huslToLch(vec4 c) {return vec4(  huslToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4  lchToHusl(vec4 c) {return vec4(  lchToHusl( vec3(c.x,c.y,c.z) ), c.a);}
vec4 huslpToLch(vec4 c) {return vec4( huslpToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4 lchToHuslp(vec4 c) {return vec4( lchToHuslp( vec3(c.x,c.y,c.z) ), c.a);}
vec4   lchToRgb(vec4 c) {return vec4(   lchToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4   rgbToLch(vec4 c) {return vec4(   rgbToLch( vec3(c.x,c.y,c.z) ), c.a);}
vec4  huslToRgb(vec4 c) {return vec4(  huslToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4  rgbToHusl(vec4 c) {return vec4(  rgbToHusl( vec3(c.x,c.y,c.z) ), c.a);}
vec4 huslpToRgb(vec4 c) {return vec4( huslpToRgb( vec3(c.x,c.y,c.z) ), c.a);}
vec4 rgbToHuslp(vec4 c) {return vec4( rgbToHuslp( vec3(c.x,c.y,c.z) ), c.a);}
vec4   luvToRgb(vec4 c) {return vec4(   luvToRgb( vec3(c.x,c.y,c.z) ), c.a);}
// allow 3 floats
vec3   xyzToRgb(float x, float y, float z) {return   xyzToRgb( vec3(x,y,z) );}
vec3   rgbToXyz(float x, float y, float z) {return   rgbToXyz( vec3(x,y,z) );}
vec3   xyzToLuv(float x, float y, float z) {return   xyzToLuv( vec3(x,y,z) );}
vec3   luvToXyz(float x, float y, float z) {return   luvToXyz( vec3(x,y,z) );}
vec3   luvToLch(float x, float y, float z) {return   luvToLch( vec3(x,y,z) );}
vec3   lchToLuv(float x, float y, float z) {return   lchToLuv( vec3(x,y,z) );}
vec3  huslToLch(float x, float y, float z) {return  huslToLch( vec3(x,y,z) );}
vec3  lchToHusl(float x, float y, float z) {return  lchToHusl( vec3(x,y,z) );}
vec3 huslpToLch(float x, float y, float z) {return huslpToLch( vec3(x,y,z) );}
vec3 lchToHuslp(float x, float y, float z) {return lchToHuslp( vec3(x,y,z) );}
vec3   lchToRgb(float x, float y, float z) {return   lchToRgb( vec3(x,y,z) );}
vec3   rgbToLch(float x, float y, float z) {return   rgbToLch( vec3(x,y,z) );}
vec3  huslToRgb(float x, float y, float z) {return  huslToRgb( vec3(x,y,z) );}
vec3  rgbToHusl(float x, float y, float z) {return  rgbToHusl( vec3(x,y,z) );}
vec3 huslpToRgb(float x, float y, float z) {return huslpToRgb( vec3(x,y,z) );}
vec3 rgbToHuslp(float x, float y, float z) {return rgbToHuslp( vec3(x,y,z) );}
vec3   luvToRgb(float x, float y, float z) {return   luvToRgb( vec3(x,y,z) );}
// allow 4 floats
vec4   xyzToRgb(float x, float y, float z, float a) {return   xyzToRgb( vec4(x,y,z,a) );}
vec4   rgbToXyz(float x, float y, float z, float a) {return   rgbToXyz( vec4(x,y,z,a) );}
vec4   xyzToLuv(float x, float y, float z, float a) {return   xyzToLuv( vec4(x,y,z,a) );}
vec4   luvToXyz(float x, float y, float z, float a) {return   luvToXyz( vec4(x,y,z,a) );}
vec4   luvToLch(float x, float y, float z, float a) {return   luvToLch( vec4(x,y,z,a) );}
vec4   lchToLuv(float x, float y, float z, float a) {return   lchToLuv( vec4(x,y,z,a) );}
vec4  huslToLch(float x, float y, float z, float a) {return  huslToLch( vec4(x,y,z,a) );}
vec4  lchToHusl(float x, float y, float z, float a) {return  lchToHusl( vec4(x,y,z,a) );}
vec4 huslpToLch(float x, float y, float z, float a) {return huslpToLch( vec4(x,y,z,a) );}
vec4 lchToHuslp(float x, float y, float z, float a) {return lchToHuslp( vec4(x,y,z,a) );}
vec4   lchToRgb(float x, float y, float z, float a) {return   lchToRgb( vec4(x,y,z,a) );}
vec4   rgbToLch(float x, float y, float z, float a) {return   rgbToLch( vec4(x,y,z,a) );}
vec4  huslToRgb(float x, float y, float z, float a) {return  huslToRgb( vec4(x,y,z,a) );}
vec4  rgbToHusl(float x, float y, float z, float a) {return  rgbToHusl( vec4(x,y,z,a) );}
vec4 huslpToRgb(float x, float y, float z, float a) {return huslpToRgb( vec4(x,y,z,a) );}
vec4 rgbToHuslp(float x, float y, float z, float a) {return rgbToHuslp( vec4(x,y,z,a) );}
vec4   luvToRgb(float x, float y, float z, float a) {return   luvToRgb( vec4(x,y,z,a) );}

/*
END HUSL-GLSL
*/

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

    float[] rels=float[5](4.,3.,2.,1.,.5);
    float[] alphas=float[5](.1,.2,.3,.5,1.);
    //float[] rels=float[1](1.0);
    //float[] alphas=float[1](1.0);
    vec3 rgb=getRGB(qt_TexCoord0.x);
    out_Color=vec4(0.001,0.001,0.001,0.001);
    for (int i=0;i<5;i++){
        float r=rels[i];
        float a=alphas[i];
        float max_=.5+sample1.r*r;
        float min_=.5-sample1.g*r;
        if(min_<=h && h <=max_)
            out_Color=vec4(rgb*a,a);
    }
}
 
        "
    }

    WebSocket {
        id: socket
        onTextMessageReceived: {
            messageBox.source = message
        }
    }

    Image {
        id: messageBox
        visible:false
    }

    function restart_socket(){
        socket.url=plasmoid.configuration.panonServer;
        socket.active=false; socket.active=true; 
    }

    Timer {
        interval: 20
        repeat: true
        running: true 
        onTriggered: {
            if(socket.status == WebSocket.Error) {
                restart_socket()
                console.log("Error: " + socket.errorString)
            } else if (socket.status == WebSocket.Open) {
                socket.sendBinaryMessage("b");
            } else if (socket.status == WebSocket.Closed) {
                restart_socket()
                console.log("closed: " + socket.errorString)
                console.log(socket.url)
            }
        }
    }
}


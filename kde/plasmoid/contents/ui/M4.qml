
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
        property variant tex1:messageBox
        anchors.fill: parent
        blending: true
        fragmentShader: "#version 400
uniform sampler2D tex1;
varying mediump vec2 qt_TexCoord0;
out vec4 out_Color;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main()
{
    vec4 sample1= texture(tex1, vec2(qt_TexCoord0.x,0.5)) ;
    float h=qt_TexCoord0.y;

    float[] rels=float[5](4.,3.,2.,1.,.5);
    float[] alphas=float[5](.1,.2,.3,.5,1.);
    //float[] rels=float[1](1.0);
    //float[] alphas=float[1](1.0);
    vec3 hsv=vec3(qt_TexCoord0.x*1.5+0.5,1,1);
    vec3 rgb=hsv2rgb(hsv);
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


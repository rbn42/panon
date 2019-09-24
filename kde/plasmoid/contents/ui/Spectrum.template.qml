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
        husl-glsl.fsh
        panon.frag 
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

import QtQuick 2.0
import QtWebSockets 1.0
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item{
    Layout.preferredWidth: plasmoid.configuration.preferredWidth
    Layout.fillWidth:plasmoid.configuration.autoExtend 

    ShaderEffect {
        readonly property bool colorSpaceHSL:plasmoid.configuration.colorSpaceHSL
        readonly property bool colorSpaceHSLuv:plasmoid.configuration.colorSpaceHSLuv

        readonly property int hslHueFrom    :plasmoid.configuration.hslHueFrom
        readonly property int hslHueTo    :plasmoid.configuration.hslHueTo
        readonly property int hsluvHueFrom  :plasmoid.configuration.hsluvHueFrom
        readonly property int hsluvHueTo  :plasmoid.configuration.hsluvHueTo
        readonly property int hslSaturation  :plasmoid.configuration.hslSaturation
        readonly property int hslLightness   :plasmoid.configuration.hslLightness
        readonly property int hsluvSaturation:plasmoid.configuration.hsluvSaturation
        readonly property int hsluvLightness :plasmoid.configuration.hsluvLightness

        property variant tex1:texture
        anchors.fill: parent
        blending: true
        fragmentShader: "#version 400
        husl-glsl.fsh
        panon.frag 
        "
    }

    WebSocket {
        id: socket
        url:"ws://localhost:"+plasmoid.configuration.serverPort
        onTextMessageReceived: {
            messageBox= message
        }
        onStatusChanged: if (socket.status == WebSocket.Error) {
                             console.log("Error: " + socket.errorString)
                             // Automatically reconnect.
                             reconnect.running=true
                         } else if (socket.status == WebSocket.Closed) {
                             console.log("Close: " + socket.errorString)
                             messageBox=''
                             reconnect.running=true
                         }
        active:false
    }

    property string messageBox; //Message holder

    Image {
        id: texture
        visible:false
    }

    Timer {
        id:reconnect
        interval: 2000
        repeat: false
        running: true
        onTriggered: {
            socket.active=false; socket.active=true; 
            sendConfig=true;
        }
    }

    property bool reduceBass:plasmoid.configuration.reduceBass
    onReduceBassChanged:sendConfig=true
    property int fps:plasmoid.configuration.fps
    onFpsChanged:sendConfig=true
    property bool sendConfig:false;

    Timer {
        interval: 1000/fps
        repeat: true
        running: true 
        onTriggered: {

            texture.source=messageBox  // Trigger 

            // Waiting for a open socket to send configurations.
            if(sendConfig)if(socket.status == WebSocket.Open){
                sendConfig=false;
                socket.sendBinaryMessage(JSON.stringify({
                    fps:fps,
                    reduceBass:reduceBass
                }));
            }
        }
    }

    function startServer(){
        if(plasmoid.configuration.startServer){
            var p_ui=plasmoid.file("ui");
            p_ui=p_ui.split('/')
            p_ui.pop(-1)
            p_ui.push('server')
            p_ui.push('run-server.sh')
            return 'sh '+'"'+p_ui.join('/')+'" '+plasmoid.configuration.serverPort;
        }else{
            return "echo do nothing";
        }
    }
    
    PlasmaCore.DataSource {
        engine: 'executable'
        connectedSources: [startServer()]
    }
}

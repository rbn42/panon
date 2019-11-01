
import QtQuick 2.0
import QtWebSockets 1.0
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Item{
    Layout.preferredWidth: plasmoid.configuration.preferredWidth
    Layout.fillWidth:plasmoid.configuration.autoExtend 

    ShaderEffect {
        id:se
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

        property double random_seed

        anchors.fill: parent
        blending: true
        fragmentShader:shaderSource.shader_source
    }

    ShaderSource{id:shaderSource}

    WebSocketServer {
        id: server
        listen: true
        onClientConnected: {
            webSocket.onTextMessageReceived.connect(function(message) {
                messageBox= message
            });
            socket=webSocket;
        }
    }

    property var socket;
    property string messageBox; //Message holder

    Image {id: texture;visible:false}

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
            se.random_seed=Math.random()
            texture.source=messageBox  // Trigger 
        }
    }

    PlasmaCore.DataSource {
        engine: 'executable'
        connectedSources: ['sh '+'"'+Utils.get_scripts_root()+'/run-client.sh'+'" '+server.port+' '+plasmoid.configuration.deviceIndex+' '+plasmoid.configuration.fps+' '+(0+plasmoid.configuration.reduceBass)+' '+(0+plasmoid.configuration.bassResolution)]
    }
    
}


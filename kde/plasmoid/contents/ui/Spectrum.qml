
import QtQuick 2.0
import QtWebSockets 1.0
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Item{
    id:root
    readonly property var cfg:plasmoid.configuration

    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)

    // Layout.minimumWidth:  cfg.autoHide ? animatedMinimum: -1
    Layout.preferredWidth: vertical ?-1: animatedMinimum
    Layout.preferredHeight: vertical ?  animatedMinimum:-1
    Layout.maximumWidth:cfg.autoHide?Layout.preferredWidth:-1
    Layout.maximumHeight:cfg.autoHide?Layout.preferredHeight:-1 

    // gravity property: Center(0), North (1), West (4), East (3), South (2)
    readonly property int gravity:{
        if(cfg.gravity>0)
            return cfg.gravity
        switch(plasmoid.location){
            case PlasmaCore.Types.TopEdge:
            return 2
            case PlasmaCore.Types.BottomEdge:
            return 1
            case PlasmaCore.Types.RightEdge:
            return 3
            case PlasmaCore.Types.LeftEdge:
            return 4
        }
        return 1
    }

    property int animatedMinimum:(!cfg.autoHide) || messageBox.length>0 ? cfg.preferredWidth:0 

    Layout.fillWidth: vertical? false:cfg.autoExtend 
    Layout.fillHeight: vertical? cfg.autoExtend :false

    ShaderEffect {
        id:se
        readonly property bool colorSpaceHSL:cfg.colorSpaceHSL
        readonly property bool colorSpaceHSLuv:cfg.colorSpaceHSLuv

        readonly property int hueFrom    :{
            if(cfg.randomColor)
                return 360*Math.random()
            if(cfg.colorSpaceHSL)
                return cfg.hslHueFrom
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvHueFrom
        }
        readonly property int hueTo    :{
            if(cfg.randomColor)
                return 360*Math.random()
            if(cfg.colorSpaceHSL)
                return cfg.hslHueTo
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvHueTo
        }
        readonly property int saturation  :{
            if(cfg.randomColor)
                return 80+20*Math.random()
            if(cfg.colorSpaceHSL)
                return cfg.hslSaturation
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvSaturation
        }
        readonly property int lightness   :{
            if(cfg.randomColor)
                return 50+50*Math.random()
            if(cfg.colorSpaceHSL)
                return cfg.hslLightness
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvLightness
        }

        property variant tex1:texture

        property double random_seed
        property int canvas_width:root.gravity<=2?se.width:se.height
        property int canvas_height:root.gravity<=2?se.height:se.width
        property int gravity:root.gravity
        property int spectrum_width:texture.width
        property int spectrum_height:texture.height

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
    property string messageBox:""; //Message holder

    Image {id: texture;visible:false}

    property bool reduceBass:cfg.reduceBass
    onReduceBassChanged:sendConfig=true
    property int fps:cfg.fps
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

    readonly property string startBackEnd:{
        var cmd='sh '+'"'+Utils.get_scripts_root()+'/run-client.sh'+'" '
        cmd+=server.port
        var be=['pyaudio','fifo'][cfg.backendIndex]
        cmd+=' --backend='+be
        if(be=='pyaudio')
            if(cfg.deviceIndex>=0)
                cmd+=' --device-index='+cfg.deviceIndex
        if(be=='fifo')
            cmd+=' --fifo-path='+cfg.fifoPath
        cmd+=' --fps='+cfg.fps
        if(cfg.reduceBass)
            cmd+=' --reduce-bass'
        cmd+=' --bass-resolution-level='+cfg.bassResolutionLevel
        return cmd
    }

    PlasmaCore.DataSource {
        engine: 'executable'
        connectedSources: [startBackEnd]
    }

    Behavior on animatedMinimum{
        enabled:cfg.animateAutoHiding
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }
}


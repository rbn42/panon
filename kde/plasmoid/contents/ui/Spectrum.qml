
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

    // Gravity property: Center(0), North (1), West (4), East (3), South (2)
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
        readonly property bool colorSpaceHSL:cfg.randomColor?false: cfg.colorSpaceHSL
        readonly property bool colorSpaceHSLuv:cfg.randomColor?true:cfg.colorSpaceHSLuv

        readonly property int hueFrom    :{
            if(cfg.randomColor)
                return 360*Math.random()
            else if(cfg.colorSpaceHSL)
                return cfg.hslHueFrom
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvHueFrom
        }
        readonly property int hueTo    :{
            if(cfg.randomColor)
                return 1080*Math.random()-360
            else if(cfg.colorSpaceHSL)
                return cfg.hslHueTo
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvHueTo
        }
        readonly property int saturation  :{
            if(cfg.randomColor)
                if(Math.abs(hueTo-hueFrom)>100)
                    return 80+20*Math.random()
                else
                    return 80+20*Math.random()
            else if(cfg.colorSpaceHSL)
                return cfg.hslSaturation
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvSaturation
        }
        readonly property int lightness   :{
            if(cfg.randomColor)
                if(Math.abs(hueTo-hueFrom)>100)
                    return 60+20*Math.random()
                else
                    return 100*Math.random()
            else if(cfg.colorSpaceHSL)
                return cfg.hslLightness
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvLightness
        }

        property variant tex1:texture
        property double random_seed

        property double iTime
        property double iTimeDelta
        property variant iResolution:Qt.vector3d(canvas_width,canvas_height,0)
        property double iFrame:0
        property variant iMouse:Qt.vector4d(0,0,0,0)
        property variant iChannel0:texture
        property variant iChannel1:texture

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
        }
    }

    property string messageBox:""; //Message holder

    Image {id: texture;visible:false}

    property double time_first_frame:Date.now()
    property double time_prev_frame:Date.now()
    Timer {
        interval: 1000/cfg.fps
        repeat: true
        running: true 
        onTriggered: {
            se.random_seed=Math.random()

            var time_current_frame=Date.now()
            se.iTime=(time_current_frame-time_first_frame) /1000.0
            se.iTimeDelta=(time_current_frame-time_prev_frame)/1000.0
            se.iFrame+=1

            texture.source=messageBox  // Trigger 

            time_prev_frame=time_current_frame
        }
    }

    readonly property string startBackEnd:{
        var cmd='sh '+'"'+Utils.get_scripts_root()+'/run-client.sh'+'" '
        cmd+=server.port
        var be=['pyaudio','fifo','sounddevice'][cfg.backendIndex]
        cmd+=' --backend='+be
        if(be=='pyaudio')
            if(cfg.deviceIndex>=0)
                cmd+=' --device-index='+cfg.deviceIndex
        if(be=='fifo')
            cmd+=' --fifo-path='+cfg.fifoPath
        cmd+=' --fps='+cfg.fps
        if(cfg.reduceBass)
            cmd+=' --reduce-bass'
        if(cfg.debugBackend)
            cmd+=' --debug'
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


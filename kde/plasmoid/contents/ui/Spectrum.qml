import QtQuick 2.0
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import QtQuick.Controls 2.0 as QQC2

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

    property int animatedMinimum:(!cfg.autoHide) || se.iChannel2.source.length>0 ? cfg.preferredWidth:0 

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

        readonly property variant iMouse:{
            switch(root.gravity){
                case 1:
                return Qt.vector4d(iMouseArea.mouseX,se.height- iMouseArea.mouseY ,0,0)
                case 2:
                return Qt.vector4d(iMouseArea.mouseX, iMouseArea.mouseY ,0,0)
                case 3:
                return Qt.vector4d(se.height-iMouseArea.mouseY, se.width-iMouseArea.mouseX ,0,0)
                case 4:
                return Qt.vector4d(se.height- iMouseArea.mouseY, iMouseArea.mouseX ,0,0)
            }
        }

        property double iTime
        property double iTimeDelta
        property variant iResolution:root.gravity<=2?Qt.vector3d(se.width,se.height,0):Qt.vector3d(se.height,se.width,0)
        property double iFrame:0
        property variant iChannel0:Image{visible:false}
        property variant iChannel1:Image{visible:false}
        property variant iChannel2:Image{visible:false}
        property variant iChannel3:Image{visible:false}

        property int gravity:root.gravity
        property int spectrum_width:iChannel1.width
        property int spectrum_height:iChannel1.height

        anchors.fill: parent
        blending: true
        fragmentShader:shaderSource.shader_source
    }


    QQC2.Label {
        id:console_output
        anchors.fill: parent
        visible:cfg.showFps
    }

    MouseArea {
        id:iMouseArea
        hoverEnabled :true
        anchors.fill: parent
    }

    ShaderSource{id:shaderSource}

    WsConnection{id:wsconn}


    Timer {
        interval: 1000/(1+cfg.fps)
        repeat: true
        running: true 
        onTriggered: {
                var time_current_frame=Date.now()
                var deltatime=(time_current_frame-time_prev_frame)/1000.0

                if(wsconn.messageBox.length<1)
                    return
                var message=wsconn.messageBox.shift()

                se.iTime=(time_current_frame-time_first_frame) /1000.0
                se.iTimeDelta=deltatime
                se.iFrame+=1
                if(cfg.showFps)
                    if(se.iFrame%30==1){
                        console_output.text='fps:'+(1000*30/(time_current_frame-time_fps_start))
                        time_fps_start=time_current_frame
                    }

                if(message.length>0){
                    var obj = JSON.parse(message)
                    se.iChannel0.source=obj.wave
                    se.iChannel1.source=obj.spectrum 
                    se.iChannel2.source=obj.max_spectrum 
                }else{
                    se.iChannel0.source=''
                    se.iChannel1.source=''
                    se.iChannel2.source=''
                }

                time_prev_frame=time_current_frame
        }
    }


    property double time_first_frame:Date.now()
    property double time_fps_start:Date.now()
    property double time_prev_frame:Date.now()
    Behavior on animatedMinimum{
        enabled:cfg.animateAutoHiding
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }
}


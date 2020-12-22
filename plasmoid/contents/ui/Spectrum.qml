import QtQuick 2.0
import QtQuick.Layouts 1.1

import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import QtQuick.Controls 2.0 as QQC2

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

    property int animatedMinimum:(!cfg.autoHide) || audioAvailable? cfg.preferredWidth:0

    Layout.fillWidth: vertical? false:cfg.autoExtend
    Layout.fillHeight: vertical? cfg.autoExtend :false

    property double random_seed:Math.random()

    ShaderEffect {
        id:mainSE
        readonly property bool colorSpaceHSL:cfg.randomColor?false: cfg.colorSpaceHSL
        readonly property bool colorSpaceHSLuv:cfg.randomColor?true:cfg.colorSpaceHSLuv

        Behavior on hueFrom{ NumberAnimation { duration: 1000} }
        Behavior on hueTo{ NumberAnimation { duration: 1000} }
        Behavior on saturation{ NumberAnimation { duration: 1000} }
        Behavior on lightness{ NumberAnimation { duration: 1000} }

        property int hueFrom    :{
            if(cfg.randomColor)
                return 360*Utils.random(random_seed+1)
            else if(cfg.colorSpaceHSL)
                return cfg.hslHueFrom
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvHueFrom
        }
        property int hueTo    :{
            if(cfg.randomColor)
                return 1080*Utils.random(random_seed+2)-360
            else if(cfg.colorSpaceHSL)
                return cfg.hslHueTo
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvHueTo
        }
        property int saturation  :{
            if(cfg.randomColor)
                if(Math.abs(hueTo-hueFrom)>100)
                    return 80+20*Utils.random(random_seed+3)
                else
                    return 80+20*Utils.random(random_seed+4)
            else if(cfg.colorSpaceHSL)
                return cfg.hslSaturation
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvSaturation
        }
        property int lightness   :{
            if(cfg.randomColor)
                if(Math.abs(hueTo-hueFrom)>100)
                    return 60+20*Utils.random(random_seed+5)
                else
                    return 100*Utils.random(random_seed+6)
            else if(cfg.colorSpaceHSL)
                return cfg.hslLightness
            else if(cfg.colorSpaceHSLuv)
                return cfg.hsluvLightness
        }

        readonly property variant iMouse:{
            switch(root.gravity){
                case 1:
                return Qt.vector4d(iMouseArea.mouseX,mainSE.height- iMouseArea.mouseY ,0,0)
                case 2:
                return Qt.vector4d(iMouseArea.mouseX, iMouseArea.mouseY ,0,0)
                case 3:
                return Qt.vector4d(mainSE.height-iMouseArea.mouseY, mainSE.width-iMouseArea.mouseX ,0,0)
                case 4:
                return Qt.vector4d(mainSE.height- iMouseArea.mouseY, iMouseArea.mouseX ,0,0)
            }
        }

        property double iTime
        property double iTimeDelta
        property double iBeat
        property variant iResolution:root.gravity<=2?Qt.vector3d(mainSE.width,mainSE.height,0):Qt.vector3d(mainSE.height,mainSE.width,0)
        property int iFrame:0
        property vector3d iChannelResolution0:iChannel0?Qt.vector3d(iChannel0.width,iChannel0.height,0):Qt.vector3d(0,0,0)
        property vector3d iChannelResolution1:iChannel1?Qt.vector3d(iChannel1.width,iChannel1.height,0):Qt.vector3d(0,0,0)
        property vector3d iChannelResolution2:iChannel2?Qt.vector3d(iChannel2.width,iChannel2.height,0):Qt.vector3d(0,0,0)
        property vector3d iChannelResolution3:iChannel3?Qt.vector3d(iChannel3.width,iChannel3.height,0):Qt.vector3d(0,0,0)
        property variant iChannel0
        property variant iChannel1
        readonly property variant iChannel2:bufferSES
        readonly property variant iChannel3:Image{source:'file://'+shaderSourceReader.texture_uri}


        property int gravity:root.gravity

        anchors.fill: parent
        blending: true
        fragmentShader:shaderSourceReader.image_shader_source
    }

    ShaderEffectSource {
        visible:false
        id:bufferSES
        width: mainSE.iResolution.x
        height: mainSE.iResolution.y
        recursive :true
        live:false
        sourceItem: ShaderEffect {
            width: mainSE.iResolution.x
            height: mainSE.iResolution.y

            readonly property double iTime:mainSE.iTime
            readonly property double iTimeDelta:mainSE.iTimeDelta
            readonly property double iBeat:mainSE.iBeat
            readonly property variant iResolution:mainSE.iResolution
            readonly property int iFrame:mainSE.iFrame
            readonly property vector3d iChannelResolution0:mainSE.iChannelResolution0
            readonly property vector3d iChannelResolution1:mainSE.iChannelResolution1
            readonly property vector3d iChannelResolution2:mainSE.iChannelResolution2
            readonly property vector3d iChannelResolution3:mainSE.iChannelResolution3
            readonly property variant iChannel0:mainSE.iChannel0
            readonly property variant iChannel1:mainSE.iChannel1
            readonly property variant iChannel2:mainSE.iChannel2
            readonly property variant iChannel3:mainSE.iChannel3
            readonly property variant iMouse:mainSE.iMouse
            readonly property int gravity:mainSE.gravity
            fragmentShader:shaderSourceReader.buffer_shader_source
        }
    }

    ShaderEffectSource {
        id:glDFTSES
        width: glDFTSE.width
        height: glDFTSE.height
        visible:false
        live:false
        sourceItem: ShaderEffect {

            id:glDFTSE
            width: 200
            height: 1
            property int dftSize:glDFTSE.width
            property int bufferSize:waveBufferSE.width
            fragmentShader:shaderSourceReader.gldft_source

            readonly property variant waveBuffer:ShaderEffectSource {
                id:waveBufferSES
                width: waveBufferSE.width
                height: waveBufferSE.height
                live:false
                sourceItem: ShaderEffect {
                    id:waveBufferSE
                    width: 2000
                    height: 2
                    property variant newWave
                    property int bufferSize:waveBufferSE.width
                    property int newWaveSize:newWave?newWave.width:0
                    readonly property variant waveBuffer:waveBufferSES
                    fragmentShader:shaderSourceReader.wave_buffer_source
                }
            }
        }
    }

    readonly property bool loadImageShaderSource:   shaderSourceReader.image_shader_source.trim().length>0
    readonly property bool loadBufferShaderSource:  shaderSourceReader.buffer_shader_source.trim().length>0
    readonly property bool failCompileImageShader:  loadImageShaderSource && false // (mainSE.status==ShaderEffect.Error)
    readonly property bool failCompileBufferShader: loadBufferShaderSource && false // (bufferSES.sourceItem.status==ShaderEffect.Error)
    property string fps_message:""
    property string error_message:
        shaderSourceReader.error_message
        + (loadImageShaderSource ?"":i18n("Error: Failed to load the visual effect. Please choose another visual effect in the configuration dialog."))
        + (failCompileImageShader?(i18n("Error: Failed to compile image shader.")+mainSE.log):"")
        + (failCompileBufferShader?(i18n("Error: Failed to compile bufffer shader.")+bufferSES.sourceItem.log):"")
    QQC2.Label {
        id:console_output
        anchors.fill: parent
        color: PlasmaCore.ColorScope.textColor
        text:error_message+(cfg.showFps?fps_message:"")
    }

    MouseArea {
        id:iMouseArea
        hoverEnabled :true
        anchors.fill: parent
        onClicked:random_seed=Math.random()
    }

    ShaderSource{id:shaderSourceReader}

    WsConnection{
        enable_wave_data:shaderSourceReader.enable_iChannel0
        enable_spectrum_data:shaderSourceReader.enable_iChannel1
        queue:MessageQueue{
            only_spectrum:shaderSourceReader.enable_iChannel1 && !shaderSourceReader.enable_iChannel0
            onImgsReadyChanged:{

                audioAvailable=imgsReady.audioAvailable
                var time_current_frame=Date.now()
                var deltatime=(time_current_frame-time_prev_frame)/1000.0
                mainSE.iTime=(time_current_frame-time_first_frame) /1000.0
                mainSE.iTimeDelta=deltatime
                mainSE.iFrame+=1
                if(cfg.showFps)
                    if(mainSE.iFrame%30==1){
                        fps_message='fps:'+ Math.round(1000*30/(time_current_frame-time_fps_start))
                        time_fps_start=time_current_frame
                    }

                        
                if(cfg.glDFT){
                    waveBufferSE.newWave=imgsReady.w;
                    waveBufferSES.scheduleUpdate();
                    glDFTSES.scheduleUpdate();
                    mainSE.iChannel1=glDFTSES;
                }else{
                    mainSE.iChannel0=imgsReady.w;
                    mainSE.iChannel1=imgsReady.s;
                    mainSE.iBeat=imgsReady.beat;
                }
                if(shaderSourceReader.enable_buffer)
                    bufferSES.scheduleUpdate();

                time_prev_frame=time_current_frame

            }
        }
    }

    property bool audioAvailable

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


import QtQuick 2.0
import QtQuick.Controls 2.0 as QQC2
import QtQuick.Scene3D 2.14
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Item{
    id:root
    readonly property var cfg:plasmoid.configuration
    property bool vertical: (plasmoid.formFactor == PlasmaCore.Types.Vertical)

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

    Behavior on animatedMinimum{
        enabled:cfg.animateAutoHiding
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }

    Layout.fillWidth: vertical? false:cfg.autoExtend
    Layout.fillHeight: vertical? cfg.autoExtend :false

    property double random_seed:Math.random()

    ShaderSource{id:shaderSourceReader}

    WsConnection{
        queue:Item{
            function push(message){
                if(message.byteLength<1){
                    audioAvailable=false
                    mainSE.enable=false
                    return;
                }
                mainSE.enable=true
                audioAvailable=true 

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
                    mainSE.npdft= new Int32Array(new Uint8Array(message));
                }

                time_prev_frame=time_current_frame
            }
        }
    }
    
    readonly property bool loadImageShaderSource:   shaderSourceReader.image_shader_source.trim().length>0
    readonly property bool loadBufferShaderSource:  shaderSourceReader.buffer_shader_source.trim().length>0
    readonly property bool failCompileImageShader:  loadImageShaderSource && false // (mainSE.status==ShaderEffect.Error)
    readonly property bool failCompileBufferShader: loadBufferShaderSource && false // (bufferSES.sourceItem.status==ShaderEffect.Error)

    property string error_message:
        shaderSourceReader.error_message
        + (loadImageShaderSource ?"":i18n("Error: Failed to load the visual effect. Please choose another visual effect in the configuration dialog."))
        + (failCompileImageShader?(i18n("Error: Failed to compile image shader.")+"mainSE.log"):"")
        + (failCompileBufferShader?(i18n("Error: Failed to compile bufffer shader.")+"bufferSES.sourceItem.log"):"")

    property string fps_message:""
    property bool audioAvailable
    property double time_first_frame:Date.now()
    property double time_fps_start:Date.now()
    property double time_prev_frame:Date.now()

    Scene3D{
        id:s3d
        visible:false
        //anchors.fill: parent
        width:root.width*2
        height:root.height
        SpScene{
            id:mainSE

            imageShaderSource:shaderSourceReader.image_shader_source
            bufferShaderSource:shaderSourceReader.buffer_shader_source

            colorSpaceHSL:cfg.randomColor?false: cfg.colorSpaceHSL
            colorSpaceHSLuv:cfg.randomColor?true:cfg.colorSpaceHSLuv

            Behavior on hueFrom{ NumberAnimation { duration: 1000} }
            Behavior on hueTo{ NumberAnimation { duration: 1000} }
            Behavior on saturation{ NumberAnimation { duration: 1000} }
            Behavior on lightness{ NumberAnimation { duration: 1000} }

            hueFrom    :{
                if(cfg.randomColor){
                    return 360*Utils.random(random_seed+1)
                }
                else if(cfg.colorSpaceHSL)
                    return cfg.hslHueFrom
                else if(cfg.colorSpaceHSLuv)
                    return cfg.hsluvHueFrom
            }
            hueTo    :{
                if(cfg.randomColor)
                    return 1080*Utils.random(random_seed+2)-360
                else if(cfg.colorSpaceHSL)
                    return cfg.hslHueTo
                else if(cfg.colorSpaceHSLuv)
                    return cfg.hsluvHueTo
            }
            saturation  :{
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
            lightness   :{
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

            iMouse:{
                switch(root.gravity){
                    case 1:
                    return Qt.vector4d(iMouseArea.mouseX,root.height- iMouseArea.mouseY ,0,0)
                    case 2:
                    return Qt.vector4d(iMouseArea.mouseX, iMouseArea.mouseY ,0,0)
                    case 3:
                    return Qt.vector4d(root.height-iMouseArea.mouseY, root.width-iMouseArea.mouseX ,0,0)
                    case 4:
                    return Qt.vector4d(root.height- iMouseArea.mouseY, iMouseArea.mouseX ,0,0)
                }
            }

            //property double iBeat
            sceneWidth:root.width
            sceneHeight:root.height
            iFrame:0

            gravity:root.gravity
        } 
    }

    ShaderEffect {
        anchors.fill: parent
        property bool blendBackground:true
        property variant tex1:ShaderEffectSource {
            hideSource:true
            format:ShaderEffectSource.RGBA
            live:true
            sourceItem:s3d
        }
        blending: true
        fragmentShader:"#version 130
            out vec4 out_Color;
            in mediump vec2 qt_TexCoord0;
            uniform sampler2D tex1;
            void main() {
                out_Color.rgb=texture(tex1,vec2(qt_TexCoord0.x/2.0,qt_TexCoord0.y)).rgb;
                out_Color.a=texture(tex1,vec2(qt_TexCoord0.x/2.0+0.5,qt_TexCoord0.y)).r;
            }" 
    }

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
        onClicked:{
            random_seed=Math.random()
        }
    }

}

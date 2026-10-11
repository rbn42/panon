import QtQuick
import QtQuick.Layouts

import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents

Item {
    id: root
    // The saved configuration, with the unapplied changes of the configuration dialog on top.
    readonly property var cfg: {
        const config = Plasmoid.configuration
        const values = {}
        for (const key of config.keys())
            values[key] = config[key]
        return Object.assign(values, config.livePreview)    // see config/ConfigPreview.qml
    }

    readonly property bool vertical: Plasmoid.formFactor == PlasmaCore.Types.Vertical

    property bool audioAvailable
    property string fps_message: ""

    // The inputs of the shaders, see ShadertoyEffect.qml.
    property double iTime
    property double iTimeDelta
    property double iBeat
    property int iFrame: 0
    readonly property vector3d iResolution: gravity <= 2 ? Qt.vector3d(width, height, 0) : Qt.vector3d(height, width, 0)
    readonly property vector4d iMouse: iMouseArea.i
    property Item iChannel0
    property Item iChannel1
    readonly property Item iChannel2: bufferSES
    readonly property Item iChannel3: textureImage

    property double time_first_frame: Date.now()
    property double time_fps_start: Date.now()
    property double time_prev_frame: Date.now()

    Layout.preferredWidth: vertical ? -1 : animatedMinimum
    Layout.preferredHeight: vertical ? animatedMinimum : -1
    Layout.maximumWidth: cfg.autoHide ? Layout.preferredWidth : -1
    Layout.maximumHeight: cfg.autoHide ? Layout.preferredHeight : -1

    // Gravity property: Center(0), North (1), South (2), East (3), West (4)
    readonly property int gravity: {
        if (cfg.gravity > 0)
            return cfg.gravity
        switch (Plasmoid.location) {
        case PlasmaCore.Types.TopEdge:
            return 2
        case PlasmaCore.Types.RightEdge:
            return 3
        case PlasmaCore.Types.LeftEdge:
            return 4
        }
        return 1
    }

    property int animatedMinimum: !cfg.autoHide || audioAvailable ? cfg.preferredWidth : 0

    Behavior on animatedMinimum {
        enabled: cfg.animateAutoHiding
        NumberAnimation {
            duration: 250
            easing.type: Easing.InCubic
        }
    }

    Layout.fillWidth: !vertical && cfg.autoExtend
    Layout.fillHeight: vertical && cfg.autoExtend

    // Created once the effect is built, so that Qt's default shader is never used.
    Loader {
        id: mainLoader
        anchors.fill: parent
        active: shaderSourceReader.loaded
        sourceComponent: ShadertoyEffect {
            inputs: root

            Behavior on hueFrom { NumberAnimation { duration: 1000 } }
            Behavior on hueTo { NumberAnimation { duration: 1000 } }
            Behavior on saturation { NumberAnimation { duration: 1000 } }
            Behavior on lightness { NumberAnimation { duration: 1000 } }

            // Color space: HSL (0), HSLuv (1)
            readonly property int colorSpace: cfg.colorSpaceHSLuv ? 1 : 0
            property int hueFrom: cfg.colorSpaceHSLuv ? cfg.hsluvHueFrom : cfg.hslHueFrom
            property int hueTo: cfg.colorSpaceHSLuv ? cfg.hsluvHueTo : cfg.hslHueTo
            property int saturation: cfg.colorSpaceHSLuv ? cfg.hsluvSaturation : cfg.hslSaturation
            property int lightness: cfg.colorSpaceHSLuv ? cfg.hsluvLightness : cfg.hslLightness

            readonly property int coord_gravity: root.gravity
            readonly property int coord_inversion: cfg.inversion ? 1 : 0

            blending: true
            fragmentShader: shaderSourceReader.image_shader_source
        }
    }

    // The buffer of effects with a buffer shader, available to the shaders as iChannel2.
    ShaderEffectSource {
        id: bufferSES
        visible: false
        width: iResolution.x
        height: iResolution.y
        recursive: true
        live: false
        sourceItem: bufferLoader.item as Item
    }

    Loader {
        id: bufferLoader
        active: shaderSourceReader.enable_buffer
        sourceComponent: ShadertoyEffect {
            inputs: root
            visible: false
            width: iResolution.x
            height: iResolution.y
            fragmentShader: shaderSourceReader.buffer_shader_source
        }
    }

    // The texture.png of the effect, available to the shaders as iChannel3.
    Image {
        id: textureImage
        visible: false
        source: shaderSourceReader.texture_uri
    }

    readonly property string error_message: {
        if (shaderSourceReader.error_message)
            return shaderSourceReader.error_message
        if (!shaderSourceReader.loaded)
            return i18n("Error: Failed to load the visual effect. Please choose another visual effect in the configuration dialog.")
        if (mainLoader.item?.status === ShaderEffect.Error)
            return i18n("Error: Failed to compile image shader.") + mainLoader.item.log
        if (bufferLoader.item?.status === ShaderEffect.Error)
            return i18n("Error: Failed to compile buffer shader.") + bufferLoader.item.log
        return wsConnection.error_message
    }

    PlasmaComponents.Label {
        anchors.fill: parent
        text: error_message + (cfg.showFps ? fps_message : "")
        wrapMode: Text.Wrap
    }

    MouseArea {
        id: iMouseArea
        anchors.fill: parent

        readonly property double current_x: root.gravity < 3 ? (cfg.inversion ? (width - mouseX) : mouseX) : (cfg.inversion ? mouseY : (height - mouseY))
        readonly property double current_y: [height - mouseY, mouseY, width - mouseX, mouseX][root.gravity - 1]
        property double lastdown_x
        property double lastdown_y
        property double lastclick_x
        property double lastclick_y

        readonly property vector4d i: Qt.vector4d(lastdown_x, lastdown_y, pressed ? lastclick_x : -lastclick_x, -lastclick_y)
        onPressed: {
            lastclick_x = current_x
            lastclick_y = current_y

            lastdown_x = current_x
            lastdown_y = current_y
        }
        onPositionChanged: {
            if (pressed) {
                lastdown_x = current_x
                lastdown_y = current_y
            }
        }
    }

    ShaderSource {
        id: shaderSourceReader
        cfg: root.cfg
    }

    MessageQueue {
        id: messageQueue
        onImgsReadyChanged: {
            audioAvailable = imgsReady.audioAvailable
            const time_current_frame = Date.now()
            iTime = (time_current_frame - time_first_frame) / 1000.0
            iTimeDelta = (time_current_frame - time_prev_frame) / 1000.0
            iFrame += 1
            // Measure the fps every 30 frames.
            if (cfg.showFps && iFrame % 30 == 1) {
                fps_message = 'fps:' + Math.round(1000 * 30 / (time_current_frame - time_fps_start))
                time_fps_start = time_current_frame
            }

            iChannel0 = imgsReady.wave
            iChannel1 = imgsReady.spectrum
            iBeat = imgsReady.beat
            if (shaderSourceReader.enable_buffer)
                bufferSES.scheduleUpdate()

            time_prev_frame = time_current_frame
        }
    }

    WsConnection {
        id: wsConnection
        cfg: root.cfg
        shaderSource: shaderSourceReader
        queue: messageQueue
    }
}

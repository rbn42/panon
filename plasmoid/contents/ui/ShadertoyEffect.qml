import QtQuick

/*
 * A shader effect with the uniforms of the Shadertoy API, see shaders/shadertoy-api-head.fsh.
 * The values are taken from the inputs object, which is shared by the image and buffer shaders.
 */
ShaderEffect {
    required property Item inputs

    readonly property double iTime: inputs.iTime
    readonly property double iTimeDelta: inputs.iTimeDelta
    readonly property double iBeat: inputs.iBeat
    readonly property int iFrame: inputs.iFrame
    readonly property vector3d iResolution: inputs.iResolution
    readonly property vector4d iMouse: inputs.iMouse
    readonly property Item iChannel0: inputs.iChannel0
    readonly property Item iChannel1: inputs.iChannel1
    readonly property Item iChannel2: inputs.iChannel2
    readonly property Item iChannel3: inputs.iChannel3
    readonly property vector3d iChannelResolution0: resolution(iChannel0)
    readonly property vector3d iChannelResolution1: resolution(iChannel1)
    readonly property vector3d iChannelResolution2: resolution(iChannel2)
    readonly property vector3d iChannelResolution3: resolution(iChannel3)

    function resolution(item) {
        return item ? Qt.vector3d(item.width, item.height, 0) : Qt.vector3d(0, 0, 0)
    }
}

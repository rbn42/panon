import QtQuick
import org.kde.plasma.plasma5support as P5Support
import "utils.js" as Utils

/*
 * This module executes a python script to build
 * the shader sources.
 */

P5Support.DataSource {

    required property var cfg
    engine: 'executable'

    property url image_shader_source: ''
    property url buffer_shader_source: ''

    property bool enable_iChannel0: false
    property bool enable_iChannel1: false

    property url texture_uri: ''
    property string error_message: ''

    readonly property bool loaded: image_shader_source.toString() !== ''
    readonly property bool enable_buffer: buffer_shader_source.toString() !== ''

    readonly property string cmd: Utils.pythonCommand('panon.effect.build_shader_source',
        [JSON.stringify([cfg.visualEffect, cfg.effectArgValues])])

    connectedSources: [cmd]

    onNewData: (sourceName, data) => {
        if (cfg.debugBackend)
            console.warn(cmd, data.stderr)
        let obj
        try {
            obj = JSON.parse(data.stdout)
        } catch (e) {
            console.warn("Failed to build the visual effect:", cmd, data.stdout, data.stderr)
            return
        }
        if ('error_code' in obj) {
            // See the error codes of build_shader_source.py.
            error_message = {
                'undeclared-argument': i18n("Error: Find undeclared arguments."),
                'compilation': i18n("Error: Failed to compile the visual effect.") + "\n" + obj.log,
                'qsb-not-found': i18n("Error: Cannot find qsb. Please install the Qt 6 shader tools."),
                'invalid-argument': i18n("Error: Invalid argument value:") + " " + obj.log,
            }[obj.error_code]
            return
        }
        enable_iChannel0 = obj.enable_iChannel0
        enable_iChannel1 = obj.enable_iChannel1
        image_shader_source = obj.image_shader
        buffer_shader_source = obj.buffer_shader
        texture_uri = obj.texture
        error_message = ''
    }
}

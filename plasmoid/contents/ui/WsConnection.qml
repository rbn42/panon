import QtQuick
import QtWebSockets
import org.kde.plasma.plasma5support as P5Support
import "utils.js" as Utils

/*
 * This module starts a python back-end client,
 * and pushes messages from the client to a queue.
 *
 * A queue is required to store new data sent from the
 * audio back-end. Because if new audio data is used
 * directly as an image by the shaders, those images
 * may be used before they are loaded, which will cause
 * flickering problems.
 */
Item {

    required property var cfg
    required property MessageQueue queue
    required property ShaderSource shaderSource

    // The last error output of the back-end, cleared once it sends data again.
    property string error_message: ''

    readonly property int minRestartDelay: 1000
    readonly property int maxRestartDelay: 60000

    WebSocketServer {
        id: server
        listen: true
        onClientConnected: webSocket => {
            webSocket.onTextMessageReceived.connect(message => {
                error_message = ''
                restartTimer.interval = minRestartDelay
                queue.push(message)
            })
        }
    }

    readonly property string startBackEnd: {
        if (server.port === 0 || !shaderSource.loaded)
            return ''
        const backend = Utils.backends[cfg.backendIndex].id
        const args = [server.url.toString(), '--backend=' + backend]
        if (backend === 'soundcard')
            args.push('--device=' + cfg.pulseaudioDevice)
        if (backend === 'fifo')
            args.push('--fifo-path=' + cfg.fifoPath)
        args.push('--fps=' + cfg.fps)
        if (cfg.reduceBass)
            args.push('--reduce-bass')
        args.push('--bass-resolution-level=' + cfg.bassResolutionLevel)
        if (shaderSource.enable_iChannel0)
            args.push('--enable-wave-data')
        if (shaderSource.enable_iChannel1)
            args.push('--enable-spectrum-data')
        const cmd = Utils.pythonCommand('panon.backend.client', args)
        if (cfg.debugBackend) {
            // Let the user start the back-end manually to see its output.
            console.warn('Executing: ' + cmd)
            return ''
        }
        return cmd
    }

    P5Support.DataSource {
        id: backEnd
        engine: 'executable'
        connectedSources: startBackEnd ? [startBackEnd] : []
        // Called when the back-end exits, e.g. after the audio device disappeared.
        onNewData: (sourceName, data) => {
            console.warn('panon back-end exited with code', data['exit code'], data.stdout, data.stderr)
            // Show the exception of a python traceback. Other output may only be warnings, e.g. from ALSA.
            error_message = data.stderr.includes('Traceback')
                ? data.stderr.trim().split('\n').pop()
                : i18n("Error: The audio back-end has stopped.")
            disconnectSource(sourceName)
            restartTimer.start()
        }
    }

    // Restart the back-end, waiting longer after each failure in a row.
    Timer {
        id: restartTimer
        interval: minRestartDelay
        onTriggered: {
            if (startBackEnd && backEnd.connectedSources.indexOf(startBackEnd) < 0)
                backEnd.connectSource(startBackEnd)
            interval = Math.min(interval * 2, maxRestartDelay)
        }
    }
}

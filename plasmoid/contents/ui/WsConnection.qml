import QtQuick 2.0
import QtWebSockets 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils
/*
 * This module starts a python back-end client, 
 * and pushs messages from the client to a queue.
 */
Item{

    readonly property var cfg:plasmoid.configuration

    property variant queue

    WebSocketServer {
        id: server
        listen: true
        onClientConnected: {
            webSocket.onTextMessageReceived.connect(function(message) {
                queue.push(message)
            });
        }
    }

    readonly property string startBackEnd:{
        var cmd=Utils.chdir_scripts_root()+'exec python3 -m panon.backend.client '
        cmd+=server.port
        var be=['pyaudio','soundcard','fifo'][cfg.backendIndex]
        cmd+=' --backend='+be
        if(be=='soundcard')
            cmd+=' --device-index="'+cfg.pulseaudioDevice+'"'
        if(be=='fifo')
            cmd+=' --fifo-path='+cfg.fifoPath
        cmd+=' --fps='+cfg.fps
        if(cfg.reduceBass)
            cmd+=' --reduce-bass'
        if(cfg.debugBackend)
            cmd+=' --debug'
        cmd+=' --bass-resolution-level='+cfg.bassResolutionLevel
        if(cfg.debugBackend){
            console.log('Executing: '+cmd)
            cmd='echo do nothing'
        }
        return cmd
    }

    PlasmaCore.DataSource {
        engine: 'executable'
        connectedSources: [startBackEnd]
        onNewData:{
            // Show back-end errors.
            console.log(data.stdout)
            console.log(data.stderr)
        }
    }

}

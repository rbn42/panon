import QtQuick 2.0
import QtWebSockets 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils
Item{

    readonly property var cfg:plasmoid.configuration

    property variant queue

    WebSocketServer {
        id: server
        listen: true
        onClientConnected: {
            webSocket.onTextMessageReceived.connect(function(message) {
                queue.push(message)
                return
            });
        }
    }

    readonly property string startBackEnd:{
        var cmd='sh '+'"'+Utils.get_scripts_root()+'/run-client.sh'+'" '
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
        return cmd
    }

    PlasmaCore.DataSource {
        engine: 'executable'
        connectedSources: [startBackEnd]
    }

}

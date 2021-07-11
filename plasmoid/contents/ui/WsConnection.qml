import QtQuick 2.0
import QtWebSockets 1.0
import org.kde.plasma.core 2.0 as PlasmaCore
import "utils.js" as Utils
// plasma pulseaudio plugin
import org.kde.plasma.private.volume 0.1 as PlasmaVolume
/*
 * This module starts a python back-end client, 
 * and pushs messages from the client to a queue.
 *
 * A queue is required to store new data sent from the 
 * audio back-end. Because if new audio data is used 
 * directly as an image by the shaders, those images 
 * may be used before they are loaded, which will cause 
 * flikering problems.
 */
Item{

    readonly property var cfg:plasmoid.configuration

    property variant queue

    property var shaderSourceReader

    WebSocketServer {
        id: server
        listen: true
        onClientConnected: {
            webSocket.onTextMessageReceived.connect(function(message) {
                queue.push(message)
            });
        }
    }

 PlasmaVolume.SinkModel {
			id: sinkModel
                        readonly property var o:PulseObject.Ports
		}

    readonly property string startBackEnd:{
        if(server.port==0) return '';
        if(shaderSourceReader.image_shader_source=='') return ''
        var cmd=Utils.chdir_scripts_root()+'exec python3 -m panon.backend.client '
        cmd+=server.url  //+':'+server.port
        var be=['pyaudio','soundcard','fifo'][cfg.backendIndex]
        cmd+=' --backend='+be
        if(be=='soundcard')
            cmd+=' --device-index="'+cfg.pulseaudioDevice+'"'
        if(be=='fifo')
            cmd+=' --fifo-path='+cfg.fifoPath
        cmd+=' --fps='+cfg.fps
        if(cfg.reduceBass)
            cmd+=' --reduce-bass'
        if(cfg.glDFT)
            cmd+=' --gldft'
        if(cfg.debugBackend)
            cmd+=' --debug'
        cmd+=' --bass-resolution-level='+cfg.bassResolutionLevel
        if(cfg.debugBackend){
            console.log('Executing: '+cmd)
            cmd='echo do nothing'
        }
        if(shaderSourceReader.enable_iChannel0)
            cmd+=' --enable-wave-data'
        if(shaderSourceReader.enable_iChannel1)
            cmd+=' --enable-spectrum-data'
        cmd+=' --num-ports='+PlasmaVolume.Ports //currentPort

        console.log('asssss')                                  //qml: asssss
        console.log(sinkModel.o)                               //qml: undefined
        console.log(PlasmaVolume.Ports)                        //qml: undefined
        console.log(PlasmaVolume.PulseObject)                  //qml: [object Object]
        console.log(sinkModel.defaultSink)                     //qml: QPulseAudio::Sink(0x17ef5f2c140)
        console.log(sinkModel.default)                         //qml: undefined
        console.log(sinkModel.default)                         //qml: undefined
        console.log(sinkModel.PulseObject)                     //qml: undefined
        console.log(PlasmaVolume.PulseObject.ports)            //qml: undefined
        console.log(PlasmaVolume.PulseObject.channels)         //qml: undefined
        console.log(PlasmaVolume.PulseObject.default)          //qml: undefined
        console.log(PlasmaVolume.PulseObject.volume)           //qml: undefined
        console.log(PlasmaVolume.PulseObject.length)           //qml: undefined
        console.log(PlasmaVolume.Description)                  //qml: undefined
        console.log('asssss2')                                 //qml: asssss2

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

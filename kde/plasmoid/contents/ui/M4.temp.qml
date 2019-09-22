import QtQuick 2.0
import QtWebSockets 1.0
import Qt3D.Core 2.0
import Qt3D.Render 2.0
import QtQuick.Layouts 1.1

Item{
    Layout.preferredWidth: 100
    Layout.fillWidth: true

    ShaderEffect {
        property variant tex1:messageBox
        anchors.fill: parent
        blending: true
        fragmentShader: "panon.frag"
    }

    WebSocket {
        id: socket
        url : "ws://localhost:8765"
        onTextMessageReceived: {
            messageBox.source = message
        }
        active:true
    }
    Image {
        id: messageBox
        visible:false
    }

    Timer {
        interval: 20
        repeat: true
        running: true 
        onTriggered: {
            if(socket.status == WebSocket.Error) {
                socket.active=false; socket.active=true; 
                console.log("Error: " + socket.errorString)
            } else if (socket.status == WebSocket.Open) {
                socket.sendBinaryMessage("b");
            } else if (socket.status == WebSocket.Closed) {
                socket.active=false; socket.active=true; 
                console.log("closed: " + socket.errorString)
            }
        }
    }
}

/**
 * 从server获取datauri,并且显示
 */
import QtQuick 2.0
import QtWebSockets 1.13
Rectangle {
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
        anchors.fill: parent
    }
    MouseArea {
        anchors.fill: parent
        onClicked: {
            socket.sendBinaryMessage("b")
        }
    }
}

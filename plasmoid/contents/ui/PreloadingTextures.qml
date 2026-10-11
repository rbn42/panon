import QtQuick

Item {

    property alias wave: waveImage
    property alias spectrum: spectrumImage
    property double beat

    readonly property bool ready: waveImage.status != Image.Loading && spectrumImage.status != Image.Loading
    property bool used: true
    property bool audioAvailable: true

    Image { id: waveImage; visible: false; cache: false }
    Image { id: spectrumImage; visible: false; cache: false }
}

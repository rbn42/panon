import QtQuick 2.0

Item{

    property variant w:Image{visible:false}
    property variant s:Image{visible:false}
    property double beat

    readonly property bool ready: (w.status!=Image.Loading) && (s.status!=Image.Loading) 
    property bool used:true
    property bool audioAvailable:true
}

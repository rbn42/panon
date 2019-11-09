import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

import org.kde.kirigami 2.3 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Kirigami.FormLayout {

    anchors.right: parent.right
    anchors.left: parent.left


    property alias cfg_reduceBass: reduceBass.checked
    property alias cfg_debugBackend: debugBackend.checked

    property alias cfg_bassResolutionLevel: bassResolutionLevel.currentIndex

    property alias cfg_backendIndex:backend.currentIndex

    property alias cfg_fifoPath: fifoPath.text

    property int cfg_deviceIndex
    property string cfg_pulseaudioDevice


    RowLayout {
        Kirigami.FormData.label: "Back end:"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:backend
            //model:  ['pyaudio (requires python3 package pyaudio)','fifo','sounddevice (requires python3 package sounddevice']
            model:  ['PortAudio','PulseAudio','fifo']
        }
    }

    RowLayout {
        visible:false // backend.currentText=='portaudio'
        Kirigami.FormData.label: "Input device:"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:deviceIndex
            model: ListModel {
                id: cbItems
            }
            textRole:'name'
            onCurrentIndexChanged:cfg_deviceIndex= cbItems.get(currentIndex).d_index
        }
    }

    RowLayout {
        visible:backend.currentText=='PulseAudio'
        Kirigami.FormData.label: "Input device:"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:pulseaudioDevice
            onCurrentIndexChanged:{
                if(currentText.length>0)
                    cfg_pulseaudioDevice= pulseaudioDevice.model[currentIndex]
            }
        }
    }

    RowLayout {
        visible:backend.currentText=='fifo'
        Kirigami.FormData.label: "Fifo path:"
        Layout.fillWidth: true

        QQC2.TextField {
            id:fifoPath
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Range:"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:bassResolutionLevel
            model:  ['0 to 22,050Hz','0 to 9,000Hz','0 to 1,800kHz']
        }
    }

    QQC2.CheckBox {
        id: reduceBass
        text: i18nc("@option:check", "Reduce the weight of bass")
    }

    QQC2.CheckBox {
        id: debugBackend
        text: i18nc("@option:check", "Debug")
    }

    readonly property string sh_get_devices:'sh '+'"'+Utils.get_scripts_root()+'/get-devices.sh'+'" '
    readonly property string sh_get_styles:'sh '+'"'+Utils.get_scripts_root()+'/get-shaders.sh'+'" '
    readonly property string sh_get_pa_devices:'sh '+'"'+Utils.get_scripts_root()+'/get-pa-devices.sh'+'" '

    PlasmaCore.DataSource {
        //id: getOptionsDS
        engine: 'executable'
        connectedSources: [
            sh_get_pa_devices
        ]
        onNewData: {

            if(sourceName==sh_get_pa_devices){
                var lst=JSON.parse(data.stdout)
                lst.unshift('auto')
                pulseaudioDevice.model=lst
                for(var i=0;i<lst.length;i++)
                    if(lst[i]==cfg_pulseaudioDevice)
                        pulseaudioDevice.currentIndex=i;
            }else if(sourceName==sh_get_styles){
            }else if(sourceName==sh_get_devices){
                var lst=JSON.parse(data.stdout)
                cbItems.append({name:'auto',d_index:-1})
                for(var i in lst)
                    cbItems.append({name:lst[i]['name'],d_index:lst[i]['index']})
                for(var i=0;i<deviceIndex.count;i++)
                    if(cbItems.get(i).d_index==cfg_deviceIndex)
                        deviceIndex.currentIndex=i;
            }else if(sourceName==sh_get_styles){
            }
        }
    }
}

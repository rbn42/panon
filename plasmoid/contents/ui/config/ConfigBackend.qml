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
        Kirigami.FormData.label: i18n("Back-end:")
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:backend
            //model:  ['pyaudio (requires python3 package pyaudio)','fifo','sounddevice (requires python3 package sounddevice']
            model:  ['PortAudio','PulseAudio','fifo']
        }
    }

    RowLayout {
        visible:false // backend.currentText=='portaudio'
        Kirigami.FormData.label: i18n("Input device:")
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
        Kirigami.FormData.label: i18n("Input device:")
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:pulseaudioDevice
            model: ListModel {
                id: pdItems
            }
            textRole:'name'
            onCurrentIndexChanged:{
                if(currentText.length>0)
                    cfg_pulseaudioDevice= pdItems.get(currentIndex).id
            }
        }
    }

    RowLayout {
        visible:backend.currentText=='fifo'
        Kirigami.FormData.label: i18n("Fifo path:")
        Layout.fillWidth: true

        QQC2.TextField {
            id:fifoPath
        }
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Audio frequency:")
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:bassResolutionLevel
            model:  ['0 to 22,050Hz','0 to 9,000Hz','0 to 3,000Hz (F7)','0 to 1,800Hz (A6)','0 to 600Hz (D5)']
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

    readonly property string sh_get_devices:Utils.chdir_scripts_root()+'python3 -m panon.backend.get_devices'
    readonly property string sh_get_pa_devices:Utils.chdir_scripts_root()+'python3 -m panon.backend.get_pa_devices'

    PlasmaCore.DataSource {
        //id: getOptionsDS
        engine: 'executable'
        connectedSources: [
            sh_get_pa_devices
        ]
        onNewData: {

            if(sourceName==sh_get_pa_devices){
                pdItems.append({name:'default',id:'default'})
                var lst=JSON.parse(data.stdout)
                for(var i in lst)
                    pdItems.append(lst[i])
                if(lst.length>1){
                    pdItems.append({name:i18n("Mixing All Microphones and Speakers"),id:'all'})
                }

                for(var i=0;i<pulseaudioDevice.count;i++)
                    if(pdItems.get(i).id==cfg_pulseaudioDevice)
                        pulseaudioDevice.currentIndex=i;
            }else if(sourceName==sh_get_devices){
                var lst=JSON.parse(data.stdout)
                cbItems.append({name:'auto',d_index:-1})
                for(var i in lst)
                    cbItems.append({name:lst[i]['name'],d_index:lst[i]['index']})
                for(var i=0;i<deviceIndex.count;i++)
                    if(cbItems.get(i).d_index==cfg_deviceIndex)
                        deviceIndex.currentIndex=i;
            }
        }
    }
}

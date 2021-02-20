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
    property alias cfg_glDFT: glDFT.checked
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

    QQC2.CheckBox {
        id: reduceBass
        text: i18nc("@option:check", "Reduce the weight of bass")
    }

    QQC2.CheckBox {
        id: glDFT
        visible:false
        text: i18nc("@option:check", "Use GLDFT (to lower CPU Usage) (experimental, not recommended)")
    }

    QQC2.CheckBox {
        id: debugBackend
        text: i18nc("@option:check", "Debug")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Audio frequency:")
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:bassResolutionLevel
            model:  ['0 to 22,050Hz','0 to 9,000Hz','0 to 3,000Hz (F7)',
            '0 to 1,800Hz (A6) with higher resolution',
            '0 to 1,800Hz (A6) with lower latency',
            '300 to 1,800Hz (A6) (filter out bass)',
            '0 to 600Hz (D5)']
        }
    }

    QQC2.Label {
        onLinkActivated: Qt.openUrlExternally(link)
        text: "<a href='https://www.szynalski.com/tone-generator/' >"+ i18n("Test your audio frequency.") + "</a>"
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Latency / resolution:")
        Layout.fillWidth: true
        QQC2.Label {
            textFormat: Text.RichText
 
            text:{
                var l;
                switch(bassResolutionLevel.currentText){

                    case '0 to 22,050Hz':
                    l=[[0,22050,16]]
                    break;

                    case '0 to 9,000Hz':
                    l=[[0,600,133],
                    [600,1800,100],
                    [1800,3000,83],
                    [3000,4800,66],
                    [4800,6600,50],
                    [6600,9000,33]];
                    break;

                    case '0 to 3,000Hz (F7)':
                    l=[[0,600,200],
                    [600,1800,133],
                    [1800,3000,66]];
                    break;

                    case '0 to 1,800Hz (A6) with higher resolution':
                    l=[[0,600,266],
                    [600,1800,200]];
                    break;

                    case '0 to 1,800Hz (A6) with lower latency':
                    l=[[0,1800,100]];
                    break;

                    case '300 to 1,800Hz (A6) (filter out bass)':
                    l=[[300,1800,100]];
                    break;

                    case '0 to 600Hz (D5)':
                    l=[[0,600,266]]
                    break;
                }
                var html='<table>'
                for(var i in l){
                    html+=('<tr><td>'+l[i][0].toLocaleString()+'</td><td>~</td><td>'
                    +l[i][1].toLocaleString()
                    +'Hz</td><td> - </td><td>'+l[i][2]+'ms / '
                    +Math.ceil((l[i][1]-l[i][0])*l[i][2]/1000)+'px</td></tr>');
                }
                html+='</table>'
                return html
            }
        }
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
                    pdItems.append({name:i18n("Monitor of Current Device"),id:'smart'})
                    pdItems.append({name:i18n("Mixing All Speakers"),id:'allspeakers'})
                    pdItems.append({name:i18n("Mixing All Microphones"),id:'allmicrophones'})
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

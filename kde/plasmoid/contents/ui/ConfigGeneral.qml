import QtQuick 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Kirigami.FormLayout {

    anchors.right: parent.right
    anchors.left: parent.left


    readonly property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical || (plasmoid.formFactor == PlasmaCore.Types.Planar && plasmoid.height > plasmoid.width)

    property alias cfg_serverPort: serverPort.text
    property alias cfg_startServer: startServer.checked
    property alias cfg_reduceBass: reduceBass.checked
    property alias cfg_fps: fps.value

    property int cfg_deviceIndex

    property alias cfg_preferredWidth: preferredWidth.value
    property alias cfg_autoExtend: autoExtend.checked

    property alias cfg_colorSpaceHSL: colorSpaceHSL.checked
    property alias cfg_colorSpaceHSLuv: colorSpaceHSLuv.checked

    property alias cfg_hslHueFrom       :hslHueFrom.value
    property alias cfg_hslHueTo         :hslHueTo.value
    property alias cfg_hsluvHueFrom     :hsluvHueFrom.value
    property alias cfg_hsluvHueTo       :hsluvHueTo.value
    property alias cfg_hslSaturation    :hslSaturation.value
    property alias cfg_hslLightness     :hslLightness.value
    property alias cfg_hsluvSaturation  :hsluvSaturation.value
    property alias cfg_hsluvLightness   :hsluvLightness.value

    property string str_options: ''

    RowLayout {
        Kirigami.FormData.label: i18nc("@title:group", "Panon server: ws://localhost:")
        Layout.fillWidth: true

        QQC2.TextField {
            id: serverPort
            Layout.fillWidth: true
            validator: IntValidator {bottom: 1; top: 30000;}
        }
    }

    QQC2.CheckBox {
        id: startServer
        text: i18nc("@option:check", "Start a server along with this widget")
    }

    RowLayout {
        Kirigami.FormData.label: "Input device"
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

    QQC2.CheckBox {
        id: reduceBass
        text: i18nc("@option:check", "Reduce the weight of bass")
    }

    QQC2.SpinBox {
        id:fps
        Kirigami.FormData.label:i18nc("@label:spinbox","Fps")
        editable:true
        stepSize:1
        from:1
        to:300
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.SpinBox {
        id: preferredWidth

        Kirigami.FormData.label: vertical ? i18nc("@label:spinbox", "Preferred height:"):i18nc("@label:spinbox", "Preferred width:")
        editable:true
        stepSize:10

        from: 1
        to:8000
    }

    QQC2.CheckBox {
        id: autoExtend
        text: i18nc("@option:check", "Fill width")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.RadioButton {
        id:colorSpaceHSL
        Kirigami.FormData.label: i18nc("@label", "Color space:")
        text: i18nc("@option:radio", "HSL")
    }

    QQC2.RadioButton {
        id:colorSpaceHSLuv
        text: i18nc("@option:radio", "HSLuv")
    }

    QQC2.SpinBox {
        id:hslHueFrom
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue from")
        visible:colorSpaceHSL.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hslHueTo
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue to")
        visible:colorSpaceHSL.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hsluvHueFrom
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue from")
        visible:colorSpaceHSLuv.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hsluvHueTo
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue to")
        visible:colorSpaceHSLuv.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hslSaturation
        Kirigami.FormData.label:i18nc("@label:spinbox","Saturation")
        visible:colorSpaceHSL.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }

    QQC2.SpinBox {
        id:hslLightness
        Kirigami.FormData.label:i18nc("@label:spinbox","Lightness")
        visible:colorSpaceHSL.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }

    QQC2.SpinBox {
        id:hsluvSaturation
        Kirigami.FormData.label:i18nc("@label:spinbox","Saturation")
        visible:colorSpaceHSLuv.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }

    QQC2.SpinBox {
        id:hsluvLightness
        Kirigami.FormData.label:i18nc("@label:spinbox","Lightness")
        visible:colorSpaceHSLuv.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }


    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.Label {
        text: str_options
    }

    PlasmaCore.DataSource {
        //id: getOptionsDS
        engine: 'executable'
        connectedSources: ['sh '+'"'+Utils.get_scripts_root()+'/get-devices.sh'+'" ']
        onNewData: {
            connectedSources.length = 0
            //if (data['exit code'] > 0) {
            //    print('Error running redshift with command: ' + sourceName + '   ...stderr: ' + data.stderr)
            //    return
            //}
            var lst=JSON.parse(data.stdout)//['lst']
            cbItems.append({name:'auto',d_index:-1})
            for(var i in lst)
                cbItems.append({name:lst[i]['name'],d_index:lst[i]['index']})
            for(var i=0;i<deviceIndex.count;i++)
                if(cbItems.get(i).d_index==cfg_deviceIndex)
                    deviceIndex.currentIndex=i;
        }
    }
}

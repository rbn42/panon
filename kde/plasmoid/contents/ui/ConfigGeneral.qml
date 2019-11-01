import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Kirigami.FormLayout {

    anchors.right: parent.right
    anchors.left: parent.left


    readonly property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical || (plasmoid.formFactor == PlasmaCore.Types.Planar && plasmoid.height > plasmoid.width)

    property alias cfg_reduceBass: reduceBass.checked
    property alias cfg_bassResolutionLevel: bassResolutionLevel.currentIndex
    property alias cfg_fps: fps.value

    property int cfg_deviceIndex
    property string cfg_shader

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

    RowLayout {
        Kirigami.FormData.label: "Range"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:bassResolutionLevel
            model:  ['0 to 44,100Hz','0 to 9,000Hz','0 to 1,800kHz']
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

    RowLayout {
        Kirigami.FormData.label: "Shader"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:shader
            model: ListModel {
                id: shaderOptions
            }
            onCurrentIndexChanged:cfg_shader= shaderOptions.get(currentIndex).text
        }
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
        id:cons
        text: str_options
    }

    readonly property string sh_get_devices:'sh '+'"'+Utils.get_scripts_root()+'/get-devices.sh'+'" '
    readonly property string sh_get_styles:'sh '+'"'+Utils.get_scripts_root()+'/get-shaders.sh'+'" '

    PlasmaCore.DataSource {
        //id: getOptionsDS
        engine: 'executable'
        connectedSources: [
            sh_get_devices,
            sh_get_styles
        ]
        onNewData: {
            if(sourceName==sh_get_devices){
                var lst=JSON.parse(data.stdout)
                cbItems.append({name:'auto',d_index:-1})
                for(var i in lst)
                    cbItems.append({name:lst[i]['name'],d_index:lst[i]['index']})
                for(var i=0;i<deviceIndex.count;i++)
                    if(cbItems.get(i).d_index==cfg_deviceIndex)
                        deviceIndex.currentIndex=i;
            }else if(sourceName==sh_get_styles){
                var lst=data.stdout.substr(0,data.stdout.length-1).split('\n')
                for(var i in lst)
                    shaderOptions.append({text:lst[i]})
                for(var i=0;i<lst.length;i++)
                    if(shaderOptions.get(i).text==cfg_shader)
                        shader.currentIndex=i;
            }
        }
    }
}

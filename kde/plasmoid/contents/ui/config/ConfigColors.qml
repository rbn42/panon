import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

import org.kde.kirigami 2.3 as Kirigami


Kirigami.FormLayout {

    anchors.right: parent.right
    anchors.left: parent.left

    property alias cfg_randomColor: randomColor.checked

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

    QQC2.CheckBox {
        id: randomColor
        text: i18nc("@option:check", "Randomize colors (on startup)")
    }
    QQC2.ButtonGroup { id: colorGroup }

    QQC2.RadioButton {
        id:colorSpaceHSL
        Kirigami.FormData.label: i18nc("@label", "Color space:")
        text: i18nc("@option:radio", "HSL")
        QQC2.ButtonGroup.group: colorGroup
    }

    QQC2.RadioButton {
        id:colorSpaceHSLuv
        text: i18nc("@option:radio", "HSLuv")
        QQC2.ButtonGroup.group: colorGroup
    }

    QQC2.SpinBox {
        id:hslHueFrom
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue from")
        visible:colorSpaceHSL.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hslHueTo
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue to")
        visible:colorSpaceHSL.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hsluvHueFrom
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue from")
        visible:colorSpaceHSLuv.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hsluvHueTo
        Kirigami.FormData.label:i18nc("@label:spinbox","Hue to")
        visible:colorSpaceHSLuv.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:10
        from:-4000
        to:4000
    }

    QQC2.SpinBox {
        id:hslSaturation
        Kirigami.FormData.label:i18nc("@label:spinbox","Saturation")
        visible:colorSpaceHSL.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }

    QQC2.SpinBox {
        id:hslLightness
        Kirigami.FormData.label:i18nc("@label:spinbox","Lightness")
        visible:colorSpaceHSL.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }

    QQC2.SpinBox {
        id:hsluvSaturation
        Kirigami.FormData.label:i18nc("@label:spinbox","Saturation")
        visible:colorSpaceHSLuv.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }

    QQC2.SpinBox {
        id:hsluvLightness
        Kirigami.FormData.label:i18nc("@label:spinbox","Lightness")
        visible:colorSpaceHSLuv.checked
        enabled:!randomColor.checked
        editable:true
        stepSize:2
        from:0
        to:100
    }


    Item {
        Kirigami.FormData.isSection: true
    }
}

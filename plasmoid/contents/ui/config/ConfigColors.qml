import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    // Show changes in the widget before they are applied.
    readonly property ConfigPreview preview: ConfigPreview { configPage: page }

    property alias cfg_colorSpaceHSLuv: colorSpaceHSLuv.checked

    property alias cfg_hslHueFrom: hslHueFrom.value
    property alias cfg_hslHueTo: hslHueTo.value
    property alias cfg_hsluvHueFrom: hsluvHueFrom.value
    property alias cfg_hsluvHueTo: hsluvHueTo.value
    property alias cfg_hslSaturation: hslSaturation.value
    property alias cfg_hslLightness: hslLightness.value
    property alias cfg_hsluvSaturation: hsluvSaturation.value
    property alias cfg_hsluvLightness: hsluvLightness.value

    component HueSpinBox: QQC2.SpinBox {
        editable: true
        stepSize: 10
        from: -4000
        to: 4000
    }

    component PercentSpinBox: QQC2.SpinBox {
        editable: true
        stepSize: 2
        from: 0
        to: 100
    }

    Kirigami.FormLayout {

        QQC2.Button {
            text: i18n("Randomize colors")
            onClicked: {
                colorSpaceHSLuv.checked = true
                hsluvHueFrom.value = 360 * Math.random()
                hsluvHueTo.value = 1080 * Math.random() - 360
                hsluvSaturation.value = 80 + 20 * Math.random()
                // A wide hue range looks best with a medium lightness.
                if (Math.abs(hsluvHueTo.value - hsluvHueFrom.value) > 100)
                    hsluvLightness.value = 60 + 20 * Math.random()
                else
                    hsluvLightness.value = 100 * Math.random()
            }
        }

        QQC2.ButtonGroup { id: colorGroup }

        QQC2.RadioButton {
            id: colorSpaceHSL
            Kirigami.FormData.label: i18nc("@label", "Color space:")
            text: i18nc("@option:radio", "HSL")
            checked: !colorSpaceHSLuv.checked
            QQC2.ButtonGroup.group: colorGroup
        }

        QQC2.RadioButton {
            id: colorSpaceHSLuv
            text: i18nc("@option:radio", "HSLuv")
            QQC2.ButtonGroup.group: colorGroup
        }

        HueSpinBox {
            id: hslHueFrom
            Kirigami.FormData.label: i18nc("@label:spinbox","Hue from")
            visible: colorSpaceHSL.checked
        }

        HueSpinBox {
            id: hslHueTo
            Kirigami.FormData.label: i18nc("@label:spinbox","Hue to")
            visible: colorSpaceHSL.checked
        }

        HueSpinBox {
            id: hsluvHueFrom
            Kirigami.FormData.label: i18nc("@label:spinbox","Hue from")
            visible: colorSpaceHSLuv.checked
        }

        HueSpinBox {
            id: hsluvHueTo
            Kirigami.FormData.label: i18nc("@label:spinbox","Hue to")
            visible: colorSpaceHSLuv.checked
        }

        PercentSpinBox {
            id: hslSaturation
            Kirigami.FormData.label: i18nc("@label:spinbox","Saturation")
            visible: colorSpaceHSL.checked
        }

        PercentSpinBox {
            id: hslLightness
            Kirigami.FormData.label: i18nc("@label:spinbox","Lightness")
            visible: colorSpaceHSL.checked
        }

        PercentSpinBox {
            id: hsluvSaturation
            Kirigami.FormData.label: i18nc("@label:spinbox","Saturation")
            visible: colorSpaceHSLuv.checked
        }

        PercentSpinBox {
            id: hsluvLightness
            Kirigami.FormData.label: i18nc("@label:spinbox","Lightness")
            visible: colorSpaceHSLuv.checked
        }
    }
}

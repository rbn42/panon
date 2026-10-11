import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

KCM.SimpleKCM {
    id: page

    // Show changes in the widget before they are applied.
    readonly property ConfigPreview preview: ConfigPreview { configPage: page }

    readonly property bool vertical: Plasmoid.formFactor == PlasmaCore.Types.Vertical

    property alias cfg_fps: fps.value
    property alias cfg_showFps: showFps.checked

    property alias cfg_preferredWidth: preferredWidth.value
    property alias cfg_autoExtend: autoExtend.checked
    property alias cfg_autoHide: autoHideBtn.checked
    property alias cfg_animateAutoHiding: animateAutoHiding.checked

    property alias cfg_gravity: gravity.currentIndex
    property alias cfg_inversion: inversion.checked

    Kirigami.FormLayout {

        QQC2.SpinBox {
            id: fps
            Kirigami.FormData.label: i18nc("@label:spinbox","FPS:")
            editable: true
            stepSize: 1
            from: 1
            to: 300
        }

        QQC2.Label {
            text: i18n("Lower FPS saves CPU and batteries.")
        }

        QQC2.CheckBox {
            id: showFps
            text: i18nc("@option:radio", "Show FPS")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.CheckBox {
            id: autoHideBtn
            text: i18nc("@option:radio", "Auto-hide (when audio is gone)")
            onToggled: {
                if (checked)
                    autoExtend.checked = false
            }
        }

        QQC2.CheckBox {
            id: animateAutoHiding
            visible: autoHideBtn.checked
            text: i18nc("@option:radio", "Animate auto-hiding")
        }

        QQC2.SpinBox {
            id: preferredWidth

            Kirigami.FormData.label: vertical ? i18nc("@label:spinbox", "Height:") : i18nc("@label:spinbox", "Width:")
            editable: true
            stepSize: 10

            from: 1
            to: 8000
        }

        QQC2.CheckBox {
            id: autoExtend
            enabled: !autoHideBtn.checked
            text: vertical ? i18nc("@option:check", "Fill height (don't work with Auto-hiding)") : i18nc("@option:check", "Fill width (don't work with Auto-hiding)")
        }

        Item {
            Kirigami.FormData.isSection: true
        }

        QQC2.ComboBox {
            id: gravity
            Kirigami.FormData.label: i18n("Gravity:")
            model: [i18n("Center"), i18n("North"), i18n("South"), i18n("East"), i18n("West")]
        }

        QQC2.CheckBox {
            id: inversion
            text: i18nc("@option:check", "Flip")
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Version:")
            text: Plasmoid.metaData.version
        }
    }
}

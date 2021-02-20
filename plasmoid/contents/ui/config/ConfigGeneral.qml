import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

import org.kde.kirigami 2.3 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Kirigami.FormLayout {
    id:root

    anchors.right: parent.right
    anchors.left: parent.left


    readonly property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical || (plasmoid.formFactor == PlasmaCore.Types.Planar && plasmoid.height > plasmoid.width)

    property alias cfg_fps: fps.value
    property alias cfg_showFps: showFps.checked
    property alias cfg_hideTooltip: hideTooltip.checked

    property alias cfg_preferredWidth: preferredWidth.value
    property alias cfg_autoExtend: autoExtend.checked
    property alias cfg_autoHide: autoHideBtn.checked
    property alias cfg_animateAutoHiding: animateAutoHiding.checked

    property alias cfg_gravity:gravity.currentIndex
    property alias cfg_inversion:inversion.checked

    QQC2.SpinBox {
        id:fps
        Kirigami.FormData.label:i18nc("@label:spinbox","FPS:")
        editable:true
        stepSize:1
        from:1
        to:300
    }

    QQC2.Label {
        text: i18n("Lower FPS saves CPU and battries.")
    }

    QQC2.CheckBox {
        id:showFps
        text: i18nc("@option:radio", "Show FPS")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id:autoHideBtn
        text: i18nc("@option:radio", "Auto-hide (when audio is gone)")
        onCheckedChanged:{
            autoExtend.checked=autoHideBtn.checked?false:autoExtend.checked
        }
    }

    QQC2.CheckBox {
        id:animateAutoHiding
        visible:autoHideBtn.checked
        text: i18nc("@option:radio", "Animate auto-hiding")
    }

    QQC2.SpinBox {
        id: preferredWidth

        Kirigami.FormData.label: vertical ? i18nc("@label:spinbox", "Height:"):i18nc("@label:spinbox", "Width:")
        editable:true
        stepSize:10

        from: 1
        to:8000
    }

    QQC2.CheckBox {
        id: autoExtend
        enabled:!autoHideBtn.checked
        text: vertical?i18nc("@option:check", "Fill height (don't work with Auto-hiding)"):i18nc("@option:check", "Fill width (don't work with Auto-hiding)")
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Gravity:")
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:gravity
            model:  [i18n("Center"),i18n("North"),i18n("South"),i18n("East"),i18n("West")]
        }
    }

    QQC2.CheckBox {
        id:inversion
        text: i18nc("@option:check", "Flip")
    }

    QQC2.CheckBox {
        id:hideTooltip
        text: i18nc("@option:check", "Hide tooltip")
    }

    RowLayout {
        Kirigami.FormData.label: i18n("Version:")
        Layout.fillWidth: true

        QQC2.Label {
            text: "0.4.5"
        }
    }

}

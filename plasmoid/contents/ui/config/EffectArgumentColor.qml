import QtQuick 2.0
import org.kde.kirigami 2.3 as Kirigami
import org.kde.kquickcontrols 2.0 as KQuickControls

KQuickControls.ColorButton {
    property var root
    property int index
    property var effectArgValues

    visible:root.effect_arguments.length>index
    Kirigami.FormData.label: visible?root.effect_arguments[index]["name"]+":":""

    showAlphaChannel:true

    color:visible?effectArgValues[index]:""

    id:btn

    onColorChanged:{
        effectArgValues[index]=btn.color
        root.cfg_effectArgTrigger=!root.cfg_effectArgTrigger
    }
}


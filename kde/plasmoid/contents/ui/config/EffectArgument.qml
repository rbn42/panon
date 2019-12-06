import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

import org.kde.kirigami 2.3 as Kirigami

RowLayout {

    property var root
    property int index
    property var effectArgValues
    property var randomEffect

    property var vali:null

    Kirigami.FormData.label: visible?root.effect_arguments[index]["name"]+":":""
    visible:root.effect_arguments.length>index
    QQC2.TextField {
        enabled:!randomEffect.checked
        text:visible? effectArgValues[index]:""
        onTextChanged:{
            effectArgValues[index]=text
            root.cfg_effectArgTrigger=!root.cfg_effectArgTrigger
        }
        validator:vali
    }
}


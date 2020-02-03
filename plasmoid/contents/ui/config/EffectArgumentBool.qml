import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

QQC2.CheckBox {

    property var root
    property int index
    property var effectArgValues

    property var randomEffect
    enabled:!randomEffect.checked

    visible:root.effect_arguments.length>index
    text: visible?root.effect_arguments[index]["name"]:""
    checked:visible?(effectArgValues[index]=="true"):false

    onCheckedChanged:{
        effectArgValues[index]=checked
        root.cfg_effectArgTrigger=!root.cfg_effectArgTrigger
    }
}

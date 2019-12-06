import QtQuick 2.0
import QtQuick.Layouts 1.1
import QtQuick.Controls 2.0 as QQC2

import org.kde.kirigami 2.3 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

import "utils.js" as Utils

Kirigami.FormLayout {
    id:root

    anchors.right: parent.right
    anchors.left: parent.left

    property string cfg_visualEffect
    property alias cfg_randomVisualEffect: randomShader.checked

    property var cfg_effectArgValues:[]

    QQC2.CheckBox {
        id: randomShader
        text: i18nc("@option:check", "Random effect (on startup)")
    }

    QQC2.Label {
        visible:randomShader.checked
        text:"Unwanted effects can be removed <br/>from <a href='file:///"+Utils.get_root()+"/shaders/' >here</a>."
        onLinkActivated: Qt.openUrlExternally(link)
    }

    RowLayout {
        Kirigami.FormData.label: "Effect:"
        Layout.fillWidth: true

        QQC2.ComboBox {
            id:visualeffect
            model: ListModel {
                id: shaderOptions
            }
            onCurrentIndexChanged:cfg_visualEffect= shaderOptions.get(currentIndex).text
            enabled:!randomShader.checked
        }
    }

    RowLayout {
        Kirigami.FormData.label: "Hint:"
        Layout.fillWidth: true
        visible:hint.text.length>0
        QQC2.Label {
            id:hint
            text:''
        }
    }

    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[0]["name"]+":":""
        visible:effect_arguments.length>0
        QQC2.TextField {
            id:effectArgValue0
            enabled:!randomShader.checked
            text:cfg_effectArgValues[0]?cfg_effectArgValues[0]:""
            onTextChanged:cfg_effectArgValues[0]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[1]["name"]+":":""
        visible:effect_arguments.length>1
        QQC2.TextField {
            id:effectArgValue1
            enabled:!randomShader.checked
            text:cfg_effectArgValues[1]?cfg_effectArgValues[1]:""
            onTextChanged:cfg_effectArgValues[1]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[2]["name"]+":":""
        visible:effect_arguments.length>2
        QQC2.TextField {
            id:effectArgValue2
            enabled:!randomShader.checked
            text:cfg_effectArgValues[2]?cfg_effectArgValues[2]:""
            onTextChanged:cfg_effectArgValues[2]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[3]["name"]+":":""
        visible:effect_arguments.length>3
        QQC2.TextField {
            id:effectArgValue3
            enabled:!randomShader.checked
            text:cfg_effectArgValues[3]?cfg_effectArgValues[3]:""
            onTextChanged:cfg_effectArgValues[3]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[4]["name"]+":":""
        visible:effect_arguments.length>4
        QQC2.TextField {
            id:effectArgValue4
            enabled:!randomShader.checked
            text:cfg_effectArgValues[4]?cfg_effectArgValues[4]:""
            onTextChanged:cfg_effectArgValues[4]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[5]["name"]+":":""
        visible:effect_arguments.length>5
        QQC2.TextField {
            id:effectArgValue5
            enabled:!randomShader.checked
            text:cfg_effectArgValues[5]?cfg_effectArgValues[5]:""
            onTextChanged:cfg_effectArgValues[5]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[6]["name"]+":":""
        visible:effect_arguments.length>6
        QQC2.TextField {
            id:effectArgValue6
            enabled:!randomShader.checked
            text:cfg_effectArgValues[6]?cfg_effectArgValues[6]:""
            onTextChanged:cfg_effectArgValues[6]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[7]["name"]+":":""
        visible:effect_arguments.length>7
        QQC2.TextField {
            id:effectArgValue7
            enabled:!randomShader.checked
            text:cfg_effectArgValues[7]?cfg_effectArgValues[7]:""
            onTextChanged:cfg_effectArgValues[7]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[8]["name"]+":":""
        visible:effect_arguments.length>8
        QQC2.TextField {
            id:effectArgValue8
            enabled:!randomShader.checked
            text:cfg_effectArgValues[8]?cfg_effectArgValues[8]:""
            onTextChanged:cfg_effectArgValues[8]=text
        }
    }
    RowLayout {
        Kirigami.FormData.label: visible?effect_arguments[9]["name"]+":":""
        visible:effect_arguments.length>9
        QQC2.TextField {
            id:effectArgValue9
            enabled:!randomShader.checked
            text:cfg_effectArgValues[9]?cfg_effectArgValues[9]:""
            onTextChanged:cfg_effectArgValues[9]=text
        }
    }

    readonly property string sh_get_devices:'sh '+'"'+Utils.get_scripts_root()+'/get-devices.sh'+'" '
    readonly property string sh_get_styles:'sh '+'"'+Utils.get_scripts_root()+'/get-shaders.sh'+'" '

    readonly property string sh_read_effect_hint:Utils.read_shader(cfg_visualEffect+'hint.html')
    readonly property string sh_read_effect_args:Utils.read_shader(cfg_visualEffect+'arguments.json')

    onCfg_visualEffectChanged:{
        hint.text=''
        effect_arguments=[]
    }
    property bool firstTimeLoadArgs:true
    property var effect_arguments:[]

     IntValidator{id:intvali}
     DoubleValidator{id:doublevali}
     
    PlasmaCore.DataSource {
        //id: getOptionsDS
        engine: 'executable'
        connectedSources: {
            if(shaderOptions.count<1)return[sh_get_styles]

            if(cfg_visualEffect.endsWith('/'))return[sh_read_effect_hint,sh_read_effect_args]

            return []
        }
        
        onNewData: {
            if(sourceName==sh_get_devices){
            }else if(sourceName==sh_read_effect_hint){
                hint.text=(data.stdout)
            }else if(sourceName==sh_read_effect_args){
                if(data.stdout.length>0){
                    effect_arguments=JSON.parse(data.stdout)
                    var textfieldlst=[
                        effectArgValue0,effectArgValue1,effectArgValue2,effectArgValue3,effectArgValue4,
                        effectArgValue5,effectArgValue6,effectArgValue7,effectArgValue8,effectArgValue9
                    ]
                    for(var index=0;index<textfieldlst.length;index++){
                        if(index>=effect_arguments.length)break
                        var arg=effect_arguments[index]
                        var textfield=textfieldlst[index]
                        if(!firstTimeLoadArgs)
                            textfield.text=arg["default"]
                        if(textfield.text.length<1)
                            textfield.text=arg["default"]
                        if(arg["type"])
                            textfield.validator={'int':intvali,'double':doublevali}[arg["type"]]
                        else
                            textfield.validator=null
                    }
                }
                firstTimeLoadArgs=false
            }else if(sourceName==sh_get_styles){
                var lst=data.stdout.substr(0,data.stdout.length-1).split('\n')
                for(var i in lst)
                    shaderOptions.append({text:lst[i]})
                for(var i=0;i<lst.length;i++)
                    if(shaderOptions.get(i).text==cfg_visualEffect)
                        visualeffect.currentIndex=i;
            }
        }
    }
}

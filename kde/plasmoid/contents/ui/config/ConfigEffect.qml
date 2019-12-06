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
    property alias cfg_randomVisualEffect: randomEffect.checked

    property var cfg_effectArgValues:[]
    property bool cfg_effectArgTrigger:false

    QQC2.CheckBox {
        id: randomEffect
        text: i18nc("@option:check", "Random effect (on startup)")
    }

    QQC2.Label {
        visible:randomEffect.checked
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
            enabled:!randomEffect.checked
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

     
    PlasmaCore.DataSource {
        //id: getOptionsDS
        engine: 'executable'
        connectedSources: {
            if(shaderOptions.count<1)return[sh_get_styles]

            if(cfg_visualEffect.endsWith('/'))return[sh_read_effect_hint,sh_read_effect_args]

            return []
        }
        property var textfieldlst:[]
        
        onNewData: {
            if(sourceName==sh_get_devices){
            }else if(sourceName==sh_read_effect_hint){
                hint.text=(data.stdout)
            }else if(sourceName==sh_read_effect_args){
                if(data.stdout.length>0){
                    effect_arguments=JSON.parse(data.stdout)
                    //while(textfieldlst.length>0)textfieldlst.pop().destroy() 
                    textfieldlst.map(function(o){o.visible=false})
                    for(var index=0;index<effect_arguments.length;index++){
                        var arg=effect_arguments[index]
                        if(!firstTimeLoadArgs)
                            cfg_effectArgValues[index]=arg['default']
                        
                        var component
                        if(arg['type'])
                            component= Qt.createComponent({
                                "int":"EffectArgumentInt.qml",
                                "double":"EffectArgumentDouble.qml",
                                "bool":"EffectArgumentBool.qml",
                            }[arg["type"]]);
                        else
                            component= Qt.createComponent("EffectArgument.qml");
                        var obj= component.createObject(root, {
                            index:index,
                            root:root,
                            effectArgValues:cfg_effectArgValues,
                            randomEffect:randomEffect
                        });
                            
                        textfieldlst.push(obj)
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

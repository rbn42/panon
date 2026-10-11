import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.kquickcontrols as KQuickControls
import org.kde.newstuff as NewStuff
import org.kde.plasma.plasma5support as P5Support

import "../utils.js" as Utils

KCM.SimpleKCM {
    id: page

    // Show changes in the widget before they are applied.
    readonly property ConfigPreview preview: ConfigPreview { configPage: page }

    property string cfg_visualEffect
    property var cfg_effectArgValues: []

    // [{name, id, hint, arguments}], see get_effect_list.py
    property var effects: []
    property int effectIndex: -1
    readonly property var currentEffect: effects[effectIndex] ?? null
    readonly property var effectArguments: currentEffect ? currentEffect.arguments : []

    function argValue(index, arg) {
        return index < cfg_effectArgValues.length ? cfg_effectArgValues[index] : String(arg.default)
    }

    // Assign a new list, so that the configuration dialog notices the modification.
    function setArgValue(index, value) {
        const values = effectArguments.map((arg, i) => argValue(i, arg))
        values[index] = String(value)
        cfg_effectArgValues = values
    }

    Kirigami.FormLayout {

        NewStuff.Button {
            downloadNewWhat: i18n("Effects")
            configFile: Utils.packagePath("config/panon.knsrc")
            onEntryEvent: (entry, event) => {
                if (event === NewStuff.Entry.StatusChangedEvent)
                    effectListSource.reload()
            }
        }

        QQC2.ComboBox {
            id: visualeffect
            Kirigami.FormData.label: i18n("Effect:")
            model: effects
            textRole: 'name'
            currentIndex: effectIndex
            onActivated: {
                effectIndex = currentIndex
                cfg_visualEffect = currentEffect.id
                cfg_effectArgValues = effectArguments.map(arg => String(arg.default))
            }
        }

        QQC2.Label {
            Kirigami.FormData.label: i18n("Hint:")
            visible: text.length > 0
            text: currentEffect ? currentEffect.hint : ''
            onLinkActivated: link => Qt.openUrlExternally(link)
        }

        Repeater {
            model: effectArguments
            delegate: Loader {
                required property var modelData
                required property int index
                Kirigami.FormData.label: modelData.type === 'bool' ? '' : modelData.name + ':'
                sourceComponent: ({ bool: boolArgument, color: colorArgument })[modelData.type] ?? textArgument
            }
        }
    }

    // The parent of these components is the Loader in the Repeater above.
    Component {
        id: textArgument
        QQC2.TextField {
            readonly property var arg: parent.modelData
            readonly property int index: parent.index
            readonly property bool isInt: arg.type === 'int'
            readonly property bool isDouble: arg.type === 'double' || arg.type === 'float'

            text: argValue(index, arg)
            validator: isInt ? intValidator : isDouble ? doubleValidator : null
            onTextEdited: setArgValue(index, text)

            IntValidator {
                id: intValidator
                bottom: arg.min ?? -1000000
                top: arg.max ?? 1000000
            }
            DoubleValidator {
                id: doubleValidator
                bottom: arg.min ?? -1000000
                top: arg.max ?? 1000000
                notation: DoubleValidator.StandardNotation
            }
        }
    }

    Component {
        id: boolArgument
        QQC2.CheckBox {
            readonly property var arg: parent.modelData
            readonly property int index: parent.index
            text: arg.name
            checked: argValue(index, arg) === 'true'
            onToggled: setArgValue(index, checked)
        }
    }

    Component {
        id: colorArgument
        KQuickControls.ColorButton {
            readonly property var arg: parent.modelData
            readonly property int index: parent.index
            showAlphaChannel: true
            color: argValue(index, arg)
            onAccepted: color => setArgValue(index, color)
        }
    }

    P5Support.DataSource {
        id: effectListSource
        engine: 'executable'
        readonly property string cmd: Utils.pythonCommand('panon.effect.get_effect_list')
        connectedSources: [cmd]

        function reload() {
            disconnectSource(cmd)
            connectSource(cmd)
        }

        onNewData: (sourceName, data) => {
            const lst = JSON.parse(data.stdout || '[]')
            // Select the configured effect, or the default effect.
            let index = lst.findIndex(effect => effect.id == cfg_visualEffect)
            if (index < 0)
                index = lst.findIndex(effect => effect.name == 'default')
            effectIndex = index
            effects = lst
        }
    }
}

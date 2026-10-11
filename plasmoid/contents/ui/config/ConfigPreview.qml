import QtQuick
import org.kde.plasma.plasmoid

/*
 * Shows the changes of a configuration page in the widget before they are applied.
 *
 * The changed values are published in the undeclared configuration key "livePreview",
 * which only exists in memory and is never written to disk. The widget shows them on
 * top of the saved configuration (see Spectrum.qml). Saving is left to the configuration
 * dialog, which writes the values when they are applied. The preview ends when the page
 * or the dialog is closed, so that the widget shows the saved configuration again.
 */
QtObject {
    required property Item configPage

    function keys() {
        return Plasmoid.configuration.keys().filter(key => ('cfg_' + key) in configPage)
    }

    function update() {
        const preview = {}
        for (const key of keys())
            preview[key] = configPage['cfg_' + key]
        Plasmoid.configuration.livePreview = preview
    }

    function clear() {
        Plasmoid.configuration.livePreview = {}
    }

    Component.onCompleted: {
        for (const key of keys())
            configPage['cfg_' + key + 'Changed'].connect(update)
    }

    Component.onDestruction: clear()

    readonly property Connections windowConnection: Connections {
        target: configPage.Window.window
        function onVisibleChanged() {
            if (!target.visible)
                clear()
        }
    }
}

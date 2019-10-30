import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18nc("@title", "General")
         icon: "music"
         source: "ConfigGeneral.qml"
    }
    /*
    ConfigCategory {
         name: i18n('Backend')
         icon: 'music'
         source: 'config/ConfigBackend.qml'
    }
    */
}

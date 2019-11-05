import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18nc("@title", "General")
         icon: "music"
         source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
         name: i18n('Backend')
         icon: 'server'
         source: 'config/ConfigBackend.qml'
    }
    ConfigCategory {
         name: i18n('Colors')
         icon: 'colors'
         source: 'config/ConfigColors.qml'
    }
}

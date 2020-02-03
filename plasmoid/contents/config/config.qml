import QtQuick 2.0
import org.kde.plasma.configuration 2.0

ConfigModel {
    ConfigCategory {
         name: i18nc("@title","General")
         icon: "applications-multimedia"
         source: "config/ConfigGeneral.qml"
    }
    ConfigCategory {
         name: i18nc("@title", "Visual Effects")
         icon: "applications-graphics"
         source: "config/ConfigEffect.qml"
    }
    ConfigCategory {
         name: i18nc("@title","Back-end")
         icon: 'preferences-desktop-sound'
         source: 'config/ConfigBackend.qml'
    }
    ConfigCategory {
         name: i18nc("@title","Colors")
         icon: 'preferences-desktop-color'
         source: 'config/ConfigColors.qml'
    }
}

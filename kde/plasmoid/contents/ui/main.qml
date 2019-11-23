import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0

Item {

    readonly property var cfg:plasmoid.configuration

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Spectrum{}

    Plasmoid.toolTipItem: cfg.hideTooltip?tooltipitem:null

    Item{id:tooltipitem}

}

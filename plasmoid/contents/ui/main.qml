import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {

    readonly property var cfg:plasmoid.configuration

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    //Plasmoid.compactRepresentation: Spectrum{}
    Plasmoid.compactRepresentation:PlasmoidViewer{}

    Plasmoid.toolTipItem: cfg.hideTooltip?tooltipitem:null

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    Item{id:tooltipitem}

}

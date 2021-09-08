import QtQuick 2.0
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore

Item {

    readonly property var cfg: plasmoid.configuration

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    Plasmoid.compactRepresentation: Spectrum{}

    Plasmoid.toolTipMainText: !cfg.hideTooltip ? mediaSource.track : ""
    Plasmoid.toolTipSubText: (!cfg.hideTooltip && mediaSource.artist) ? (mediaSource.artist + " - " + mediaSource.album) : ""

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground

    PlasmaCore.DataSource {
        id: mediaSource
        engine: "mpris2"
        connectedSources: sources

        property var currentData: data["@multiplex"]
        property var currentMetadata: currentData ? currentData.Metadata : {}
        property string track: currentMetadata ? currentMetadata["xesam:title"] || "" : ""
        property string artist: currentMetadata ? currentMetadata["xesam:artist"] || "" : ""
		property string album: currentMetadata ? currentMetadata["xesam:album"] || "" : ""
    }

}

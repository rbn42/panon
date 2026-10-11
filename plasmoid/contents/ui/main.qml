import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    // Always show the spectrum inline, never as a popup.
    preferredRepresentation: fullRepresentation
    fullRepresentation: Spectrum {}

    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground
}

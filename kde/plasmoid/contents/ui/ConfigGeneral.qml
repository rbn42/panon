/*
 *  Copyright 2015 David Rosca <nowrep@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU General Public License as
 *  published by the Free Software Foundation; either version 2 of
 *  the License or (at your option) version 3 or any later version
 *  accepted by the membership of KDE e.V. (or its successor approved
 *  by the membership of KDE e.V.), which shall act as a proxy
 *  defined in Section 14 of version 3 of the license.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>
 */

import QtQuick 2.5
import QtQuick.Layouts 1.3
import QtQuick.Controls 2.5 as QQC2

import org.kde.kirigami 2.8 as Kirigami
import org.kde.plasma.core 2.0 as PlasmaCore

Kirigami.FormLayout {

    anchors.right: parent.right
    anchors.left: parent.left

    readonly property bool vertical: plasmoid.formFactor == PlasmaCore.Types.Vertical || (plasmoid.formFactor == PlasmaCore.Types.Planar && plasmoid.height > plasmoid.width)

    property alias cfg_preferredWidth: preferredWidth.value
    property alias cfg_panonServer: panonServer.text
    property alias cfg_autoExtend: autoExtend.checked

    RowLayout {
        Kirigami.FormData.label: i18nc("@title:group", "Panon server:")
        Layout.fillWidth: true

        QQC2.TextField {
            id: panonServer
            Layout.fillWidth: true
        }
    }

    Item {
        Kirigami.FormData.isSection: true
    }

    QQC2.CheckBox {
        id: autoExtend
        text: i18nc("@option:check", "Automatic extending")
    }

    QQC2.SpinBox {
        id: preferredWidth

        Kirigami.FormData.label: vertical ? i18nc("@label:spinbox", "Preferred height:"):i18nc("@label:spinbox", "Preferred width:")

        from: 1
        to:8000
    }


    Item {
        Kirigami.FormData.isSection: true
    }


}

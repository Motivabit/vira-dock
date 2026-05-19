import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Dialogs
import org.kde.plasma.plasmoid
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: "NoBackground"
    preferredRepresentation: fullRepresentation

    property int targetIconIndex: -1

    ListModel {
        id: appsModel
    }

    // Dialog untuk memilih ikon kustom secara manual
    FileDialog {
        id: iconFileDialog
        title: "Choose Custom Icon"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.svg *.webp)"]
        onAccepted: {
            if (root.targetIconIndex !== -1) {
                appsModel.setProperty(root.targetIconIndex, "iconName", iconFileDialog.selectedFile.toString());
                root.saveApps();
            }
        }
    }

    Plasma5Support.DataSource {
        id: executableEngine
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName)
        }
        function run(cmd) {
            connectSource(cmd)
        }
    }

    Component.onCompleted: {
        let savedList = Plasmoid.configuration.appList || "";
        if (savedList !== "") {
            let apps = JSON.parse(savedList);
            for (let i = 0; i < apps.length; i++) {
                appsModel.append(apps[i]);
            }
        }
    }

    function saveApps() {
        let apps = [];
        for (let i = 0; i < appsModel.count; i++) {
            apps.push({
                "appId": appsModel.get(i).appId,
                      "iconName": appsModel.get(i).iconName
            });
        }
        Plasmoid.configuration.appList = JSON.stringify(apps);
    }

    fullRepresentation: Item {
        width: dockLayout.implicitWidth + 32
        height: dockLayout.implicitHeight + 32

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.1, 0.1, 0.1, Plasmoid.configuration.bgOpacity)
            radius: 16

            Behavior on color { ColorAnimation { duration: 200 } }

            // ================= VIRA =================
            Image {
                id: viraMascot
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 4

                height: parent.height * 0.8
                fillMode: Image.PreserveAspectFit

                opacity: Plasmoid.configuration.bgOpacity >= 0.2 ? 0.7 : Plasmoid.configuration.bgOpacity
                visible: Plasmoid.configuration.showViraImage

                source: Plasmoid.configuration.viraImagePath !== ""
                ? Plasmoid.configuration.viraImagePath
                : "../assets/vira.png"
            }
            // ==========================================
        }

        DropArea {
            anchors.fill: parent
            onDropped: (drop) => {
                try {
                    if (drop.hasUrls) {
                        for (let i = 0; i < drop.urls.length; i++) {
                            let rawUrl = drop.urls[i].toString();
                            let cleanUrl = rawUrl.replace("applications:", "").replace("file://", "");

                            let parts = cleanUrl.split("/");
                            let fileName = parts[parts.length - 1];
                            let appId = fileName.replace(".desktop", "");

                            let finalIcon = appId;

                            let fixers = {
                                "org.kde.dolphin": "system-file-manager",
                                "org.kde.konsole": "utilities-terminal",
                                "org.kde.gwenview": "multimedia-photo-viewer"
                            };

                            if (fixers[appId]) {
                                finalIcon = fixers[appId];
                            }

                            appsModel.append({"appId": appId, "iconName": finalIcon});
                        }
                        root.saveApps();
                    }
                } catch (e) {
                    console.error("Failed to drop application: " + e);
                }
            }
        }

        RowLayout {
            id: dockLayout
            anchors.centerIn: parent
            spacing: 20

            Kirigami.Icon {
                source: "list-add"
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64
                visible: appsModel.count === 0
                opacity: 0.3
            }

            Repeater {
                model: appsModel
                delegate: Kirigami.Icon {
                    source: model.iconName
                    Layout.preferredWidth: 64
                    Layout.preferredHeight: 64

                    Menu {
                        id: contextMenu

                        MenuItem {
                            text: "Open"
                            icon.name: "system-run"
                            onTriggered: executableEngine.run("gtk-launch '" + model.appId + "'")
                        }

                        MenuItem {
                            text: "Change Icon..."
                            icon.name: "image-edit"
                            onTriggered: {
                                root.targetIconIndex = index;
                                iconFileDialog.open();
                            }
                        }

                        MenuItem {
                            text: "Remove"
                            icon.name: "edit-delete"
                            onTriggered: {
                                appsModel.remove(index);
                                root.saveApps();
                            }
                        }
                    }

                    MouseArea {
                        id: iconMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton

                        onEntered: parent.scale = 1.15
                        onExited: parent.scale = 1.0

                        onClicked: (mouse) => {
                            if (mouse.button === Qt.LeftButton) {
                                executableEngine.run("gtk-launch '" + model.appId + "'")
                            } else if (mouse.button === Qt.RightButton) {
                                contextMenu.popup()
                            }
                        }
                    }
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }
            }
        }
    }
}

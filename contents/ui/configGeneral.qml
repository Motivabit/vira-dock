import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

Item {
    id: configRoot

    implicitWidth: 450
    implicitHeight: 180

    property alias cfg_bgOpacity: opacitySlider.value
    property alias cfg_showViraImage: showImageCheck.checked
    property alias cfg_viraImagePath: imagePathField.text

    FileDialog {
        id: imageFileDialog
        title: "Choose Custom Avatar Image"
        nameFilters: ["Image files (*.png *.jpg *.jpeg *.webp)"]
        onAccepted: {
            imagePathField.text = imageFileDialog.selectedFile.toString()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: "Opacity:"
                font.bold: true
            }
            Slider {
                id: opacitySlider
                from: 0.0
                to: 1.0
                stepSize: 0.05
                live: true
                Layout.fillWidth: true
            }
            Label {
                text: Math.round(opacitySlider.value * 100) + "%"
                Layout.preferredWidth: 40
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(1, 1, 1, 0.1)
        }

        CheckBox {
            id: showImageCheck
            text: "Enable Anime Mascot in Corner"
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: showImageCheck.checked
            opacity: showImageCheck.checked ? 1.0 : 0.4

            TextField {
                id: imagePathField
                placeholderText: "Using default vira.png"
                Layout.fillWidth: true
            }

            Button {
                text: "Browse..."
                onClicked: imageFileDialog.open()
            }
        }
    }
}

import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Dialogs 1.2
import QtQuick.Window 2.0
import Machinekit.Application 1.0

Image {
    readonly  property string activeLanguage: getLanguage()

    id: root
    fillMode: Image.PreserveAspectFit
    smooth: true
    source: "qrc:Machinekit/Application/Controls/icons/flag-" + activeLanguage
    height: dummyButton.height

    function getLanguage() {
        // uncomment the languages when supported
        var languageMap = {
          "de": "german",
          "ru": "russian",
          "es": "spanish",
          "en": "english",
          //"uk": "ukranian",
          //"it": "italian",
          //"tu": "turkish",
          "zh": "chinese",
          "fr": "french",
          "pl": "polish",
        }

        var language = ApplicationHelpers.currentLanguage;
        for (var key in languageMap) {
            if (language.indexOf(key)  == 0) {
                return languageMap[key];
            }
        }
        return "english";
    }

    function setLanguage(language) {
        ApplicationHelpers.setLanguage(language);
        restartDialog.open();
    }

    MouseArea {
        anchors.fill: parent
        onClicked: languageMenu.popup()
    }

    Menu {
        id: languageMenu

        MenuItem {
            text: qsTr("English")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-english"
            checkable: true
            checked: root.activeLanguage == "english"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("en")
        }

        MenuItem {
            text: qsTr("German")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-german"
            checkable: true
            checked: root.activeLanguage == "german"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("de")
        }

        MenuItem {
            text: qsTr("Russian")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-russian"
            checkable: true
            checked: root.activeLanguage == "russian"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("ru")
        }

        MenuItem {
            text: qsTr("Spanish")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-spanish"
            checkable: true
            checked: root.activeLanguage == "spanish"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("es")
        }

        MenuItem {
            text: qsTr("Chinese")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-chinese"
            checkable: true
            checked: root.activeLanguage == "chinese"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("zh")
        }

        MenuItem {
            text: qsTr("French")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-french"
            checkable: true
            checked: root.activeLanguage == "french"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("fr")
        }

        MenuItem {
            text: qsTr("Polish")
            iconSource: "qrc:Machinekit/Application/Controls/icons/flag-polish"
            checkable: true
            checked: root.activeLanguage == "polish"
            exclusiveGroup: exclusiveGroup
            onTriggered: root.setLanguage("pl")
        }

        ExclusiveGroup {
            id: exclusiveGroup
        }
    }

    MessageDialog {
        id: restartDialog
        title: qsTr("Restart Application")
        text: qsTr("For the change to take effect, you need to restart the application.\nRestart now?")
        standardButtons: StandardButton.Yes | StandardButton.No
        icon: StandardIcon.Question
        onYes:  ApplicationHelpers.restartApplication();
    }
}

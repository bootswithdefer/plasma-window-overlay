import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: page

    property alias cfg_thumbWidth: thumbWidth.value
    property alias cfg_thumbOpacity: thumbOpacity.value
    property alias cfg_backdropOpacity: backdropOpacity.value
    property alias cfg_topPercent: topPercent.value
    property alias cfg_edgeMargin: edgeMargin.value
    property alias cfg_bottomMargin: bottomMargin.value
    property int cfg_side: 0

    // Plasma also passes the default values; declare them to avoid warnings
    property int cfg_thumbWidthDefault
    property int cfg_thumbOpacityDefault
    property int cfg_backdropOpacityDefault
    property int cfg_topPercentDefault
    property int cfg_edgeMarginDefault
    property int cfg_bottomMarginDefault
    property int cfg_sideDefault

    Kirigami.FormLayout {
        QQC2.ComboBox {
            Kirigami.FormData.label: i18n("Screen side:")
            model: [i18n("Right"), i18n("Left")]
            currentIndex: page.cfg_side
            onActivated: page.cfg_side = currentIndex
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: thumbWidth
            Kirigami.FormData.label: i18n("Thumbnail width (px):")
            from: 100; to: 700; stepSize: 10
        }
        QQC2.SpinBox {
            id: thumbOpacity
            Kirigami.FormData.label: i18n("Thumbnail opacity (%):")
            from: 10; to: 100; stepSize: 5
        }
        QQC2.SpinBox {
            id: backdropOpacity
            Kirigami.FormData.label: i18n("Backdrop opacity (%):")
            from: 0; to: 100; stepSize: 5
        }

        Item { Kirigami.FormData.isSection: true }

        QQC2.SpinBox {
            id: topPercent
            Kirigami.FormData.label: i18n("Top of column (% of screen height):")
            from: 0; to: 90; stepSize: 5
        }
        QQC2.SpinBox {
            id: edgeMargin
            Kirigami.FormData.label: i18n("Gap from screen edge (px):")
            from: 0; to: 300; stepSize: 2
        }
        QQC2.SpinBox {
            id: bottomMargin
            Kirigami.FormData.label: i18n("Keep clear at bottom (px):")
            from: 0; to: 400; stepSize: 4
        }
    }
}

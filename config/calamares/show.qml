/* AmaiOS 安裝投影片
 * 在安裝過程中顯示功能介紹
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import io.calamares.ui 1.0

Presentation {
    id: presentation

    function nextSlide() {
        if (!presentation.goToNextSlide())
            presentation.currentSlide = 0
    }

    Timer {
        id:       slideshowTimer
        interval: 5000
        repeat:   true
        running:  presentation.activatedInCalamares
        onTriggered: presentation.nextSlide()
    }

    // ── 投影片 1：歡迎 ────────────────────────────────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "歡迎使用 AmaiOS"
                    font.pixelSize: 36
                    font.bold: true
                    color: "#ffffff"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "基於 Ubuntu 24.04 LTS · KDE Plasma 桌面"
                    font.pixelSize: 18
                    color: "#b0bec5"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "安裝正在進行，請稍候……"
                    font.pixelSize: 14
                    color: "#64b5f6"
                }
            }
        }
    }

    // ── 投影片 2：中文支援 ────────────────────────────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#16213e"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "完整繁體中文支援"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#ffffff"
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "預裝 Fcitx5 注音輸入法"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "內建 Noto CJK 中文字型"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "預設時區：Asia/Taipei"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "LibreOffice 含繁中語言包"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                }
            }
        }
    }

    // ── 投影片 3：預裝軟體 ────────────────────────────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#0f3460"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "豐富的預裝軟體"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#ffffff"
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    columnSpacing: 40
                    rowSpacing: 10

                    Text { text: "🌐  Firefox 瀏覽器";        font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "📄  LibreOffice 辦公室套件"; font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "🎬  VLC 媒體播放器";         font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "📁  Ark 壓縮工具";           font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "🖼️  Gwenview 圖片檢視器";   font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "📖  Okular PDF 閱讀器";      font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "✏️  Kate 文字編輯器";        font.pixelSize: 15; color: "#e0e0e0" }
                    Text { text: "📊  htop 系統監控";          font.pixelSize: 15; color: "#e0e0e0" }
                }
            }
        }
    }

    // ── 投影片 4：KDE Plasma ──────────────────────────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#1a1a2e"

            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "KDE Plasma 桌面環境"
                    font.pixelSize: 30
                    font.bold: true
                    color: "#ffffff"
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "現代化、高度可自訂的桌面"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "KDE Connect 手機連動"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "Discover 軟體中心"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                    Row {
                        spacing: 12
                        Text { text: "✓"; font.pixelSize: 18; color: "#64b5f6" }
                        Text { text: "支援 Flatpak / Snap / APT"; font.pixelSize: 16; color: "#e0e0e0" }
                    }
                }
            }
        }
    }

    // ── 投影片 5：即將完成 ────────────────────────────────────────────────────
    Slide {
        Rectangle {
            anchors.fill: parent
            color: "#16213e"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "即將完成安裝"
                    font.pixelSize: 36
                    font.bold: true
                    color: "#ffffff"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "AmaiOS 0.1"
                    font.pixelSize: 22
                    color: "#64b5f6"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "感謝您選擇 AmaiOS！"
                    font.pixelSize: 16
                    color: "#b0bec5"
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "github.com/isnotamai/AmaiOS"
                    font.pixelSize: 14
                    color: "#546e7a"
                }
            }
        }
    }
}

# AmaiOS

AmaiOS 是一個基於 Ubuntu 24.04 LTS 的自訂 Linux 發行版，使用 KDE Plasma 桌面環境。

## 下載

| 版本 | 下載 |
|------|------|
| AmaiOS 0.1 | [AmaiOS-0.1-amd64.iso](https://archive.org/download/amaios-0.1/AmaiOS-0.1-amd64.iso) |

## 系統需求

| 項目 | 最低需求 |
|------|----------|
| CPU | 64-bit 雙核心 |
| RAM | 4 GB |
| 硬碟 | 25 GB |
| 顯示 | 1024×768 |

## 安裝方式

1. 下載 ISO 檔案
2. 使用 [Rufus](https://rufus.ie)（Windows）或 `dd` 指令將 ISO 寫入 USB 隨身碟
3. 從 USB 開機，選擇「Install AmaiOS」

**使用 dd 寫入 USB（Linux）：**
```bash
sudo dd if=AmaiOS-0.1-amd64.iso of=/dev/sdX bs=4M status=progress
```

## 虛擬機測試

使用 VirtualBox 或 VMware 開啟 ISO 即可測試，建議配置：
- RAM：4 GB
- 硬碟：40 GB
- 顯示：啟用 3D 加速

## 從原始碼建置

### 需求
- Ubuntu / Debian 系統（或 WSL2）
- `xorriso`, `squashfs-tools`, `wget`, `mtools`

### 步驟

```bash
# 安裝依賴
sudo apt-get install xorriso squashfs-tools wget mtools

# 下載 Kubuntu 24.04 ISO 並放到專案目錄
# 從 https://kubuntu.org/getkubuntu/ 下載

# 開始建置
sudo bash build.sh
```

建置完成後會產生 `AmaiOS-0.1-amd64.iso`。

## 專案結構

```
AmaiOS/
├── build.sh          # 主建置腳本
├── config/
│   ├── os-release    # 系統識別資訊
│   └── packages.list # 額外安裝的套件清單
├── scripts/
│   └── chroot.sh     # chroot 環境內的客製化腳本
└── branding/         # 品牌素材（桌布等）
```

## 授權

MIT License

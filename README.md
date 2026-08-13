# MODA ODF 文件應用工具擴充圖庫主題

擴充 MODA ODF 文件應用工具的圖庫內容

<https://git.ossii.com.tw/buoren/moda-odf-application-tools-extended-gallery-themes>  
[![pre-commit 框架已引入標誌](https://img.shields.io/badge/pre--commit-已引入-brightgreen?logo=pre-commit&logoColor=white "鄙專案使用 pre-commit 框架來檢查潛在問題")](https://pre-commit.com/)

## 使用說明

以下說明本產品的使用方式：

1. 自專案釋出頁面下載建構好的 LibreOffice 圖庫主題擴充功能檔案（副檔名為 `.oxt`）
1. 於 LibreOffice 產品的選單中選擇「工具」→「擴充功能」開啟「擴充功能」視窗
1. 於「擴充功能」視窗點擊下方的「加入」按鈕開啟檔案選擇對話框
1. 於檔案選擇對話框選擇下載好的 LibreOffice 圖庫主題擴充功能檔案，然後點擊「開啟」按鈕
1. 於「擴充功能軟體授權協議」對話框中確認擴充功能的授權條款，如須安裝擴充功能須接受授權條款並按下「接受」按鈕
1. 於「擴充功能」視窗點擊右下角的「關閉」按鈕關閉視窗
1. 如 LibreOffice 提示需要重新啟動，請重新啟動 LibreOffice 產品
1. 開啟側邊欄的「圖庫」按鈕開啟圖庫面板，您應可以看到安裝好的新圖庫主題

## 開發說明

以下說明本產品開發的相關細節：

### 先決條件

進行本產品的開發之前，須先滿足下列條件：

* 開發主機須安裝下列軟體：
    + Docker Engine
* 您須有開發主機的 Docker 使用權限（為 `docker` 群組之成員）
* 開發主機須有網路網路連線能力

### 產品開發流程

本產品的開發流程如下：

1. 於開發主機取出本產品的原始碼
1. 於開發主機的命令列操作介面將作業目錄切換到本產品的原始碼根目錄
1. 執行下列命令啟用開發環境容器：

    ```bash
    docker compose --profile test-environment up -d
    ```

1. 執行下列命令進入開發環境容器的命令列操作介面：

    ```bash
    docker compose --profile test exec \
        -it test-environment bash --login
    ```

1. 於開發環境容器的命令列操作介面執行下列命令部署開發環境：

    ```bash
    ./dev-assets/deploy-dev-environment.sh
    ```

1. 於類 LibreOffice 產品中建立新圖庫主題，並於其中新增圖片。
1. 於類 LibreOffice 產品的使用者資料目錄中取出圖庫主題的 sdg、sdv 與 thm 檔案，並將其放置於 [gallery](gallery) 目錄中。
1. 執行下列命令建構產品：

    ```bash
    ./build-product.sh
    ```

   建構好的擴充功能會保存在原始碼根目錄下的 `dist/release` 目錄中，檔名為 `tw.gov.moda.libreoffice.extensions.extended-gallery-themes-<版本>.oxt`。

## 授權條款

除非另有註明（個別檔案的開頭 / [檔案開頭註解](https://reuse.software/spec-3.3/#comment-headers)），本產品以[第 4.0 國際版之 Creative Commons 姓名標示-相同方式分享 授權條款](https://creativecommons.org/licenses/by-sa/4.0/)（或其任意更近期之版本）釋出供大眾於授權範圍內自由使用。

本作品遵從 [REUSE 規範](https://reuse.software/spec/)，參閱 [REUSE - Make licensing easy for everyone](https://reuse.software/) 網站以了解本產品的授權相關資訊。

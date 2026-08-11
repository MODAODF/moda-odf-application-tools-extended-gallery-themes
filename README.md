# LibreOffice 圖庫主題擴充功能專案範本

快速且精確地建立符合需求的圖庫主題 LibreOffice 擴充功能

<https://git.ossii.com.tw/buoren/libo-ext-gal-thm-template>  
[![pre-commit 框架已引入標誌](https://img.shields.io/badge/pre--commit-已引入-brightgreen?logo=pre-commit&logoColor=white "鄙專案使用 pre-commit 框架來檢查潛在問題")](https://pre-commit.com/)

## 特色

* 整合 [EditorConfig](https://editorconfig.org) 以在專案協作者間支援的純文字文件編輯器/整合式開發環境上同步偏好設定。
* 整合 [pre-commit 框架](https://pre-commit.com) 以在每次版本提交時自動檢查包含但不限於下列之潛在問題：
    + 意外提交進機敏資訊或是不適合版控的文件
    + 不一致的程式碼縮排或換行格式
    + Shell 腳本、Markdown 與 YAML 文件的撰寫
    + 智慧財產授權合規性
* 包含用於快速啟動產品開發與測試之 [Docker Compose](https://docs.docker.com/compose/) 虛擬化環境的設定檔與自動化工具
* 支援用於自動化產品建構與測試之 Forgejo 持續整合(CI)機制
* 支援用於自動化發布產品建構產物之 Forgejo 持續交付(CD)機制

## 如何使用

1. 自專案獲取一份軟體原始碼封存檔。
1. 解開軟體原始碼封存檔。
1. 將除下列之所有檔案複製進您的既有專案目錄：
    + .markdownlint.yml
    + README.md
    + README.*.md
1. 將下列檔案更名或將其內容整合進您的既有檔案：
    + real.gitattributes → .gitattributes
    + real.markdownlint.yml → .markdownlint.yml
    + real.README.md → README.md
    + real.README.zh_TW.md → README.zh_TW.md
1. （如適用）編輯新的 [README.md 讀我文件](README.md)，將下列 _佔位字_ 替換為適當之內容：
    + `_project_name_`：專案的（展示用）名稱。
    + `_project_summary_`：一個單行的專案用途文字總結。
    + `_namespace_/_project_`  
      專案網址的變動部份，如果您使用的是令一個專案託管服務的話您需要改替換完整的網址。
    + `_license_name_`：專案使用的授權條款名稱。
    + `_license_url_`：專案使用的授權條款網址。
1. 更新 [REUSE.toml reuse-tool 設定檔](REUSE.toml)中的著作權持有人名稱與宣告年份。
1. 批量將 [compose.yml](compose.yml) 檔案中的 `project-name` 佔位字替換為您專案的主機名稱(hostname)適用版名稱
1. 將所有的變更提交為一個新的修訂版（參考提交訊息：`chore: 初始化新專案`）。

您可以移除/改寫部份檔案/檔案內容以符合您專案的需求。

## 授權條款

除非另有註明（個別檔案的開頭 / [REUSE.toml](https://reuse.software/spec-3.3/#reusetoml)），本產品以 [MIT 授權條款](https://opensource.org/license/mit)釋出供大眾於授權範圍內自由使用。

本作品遵從 [REUSE 規範](https://reuse.software/spec/)，參閱 [REUSE - Make licensing easy for everyone](https://reuse.software/) 網站以了解本產品的授權相關資訊。

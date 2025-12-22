# StrengthWise 💪

> Smart Strength Training Tracker built with Flutter & Firebase.
> 基於 Flutter 與 Firebase 建構的智慧型重訓追蹤應用。

## 📖 專案簡介 (Introduction)

**StrengthWise** 是一個跨平台的健身訓練紀錄 App。旨在幫助使用者科學化管理訓練課表、紀錄組數與重量，並透過數據分析追蹤肌力成長。

本專案採用 **Flutter** 進行開發，並使用 **Firebase** 作為後端服務（Authentication, Firestore）。

## 🛠️ 技術架構 (Tech Stack)

### 前端 (Mobile/Web)
* **Framework**: [Flutter](https://flutter.dev/) (Dart)
* **State Management**: *(需查看 lib 內容確認，通常是 Provider/Riverpod/Bloc)*
* **UI Assets**: 存放於 `assets/images` 與 `signin-assets`

### 後端服務 (Backend & Cloud)
* **Platform**: [Firebase](https://firebase.google.com/)
* **Database**: Cloud Firestore (NoSQL)
* **Auth**: Firebase Authentication
* **Rules**: `firestore.rules` (資料庫安全規則)

### 資料處理工具 (Data Tools)
* **Python**: 用於資料清洗與批次匯入動作庫
    * `import_exercises.py`: 匯入訓練動作數據
    * `fillNull.py`: 資料欄位修補工具

## 🚀 快速開始 (Getting Started)

### 1. 環境準備 (Prerequisites)
確保你的開發環境已安裝：
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (最新穩定版)
* [Firebase CLI](https://firebase.google.com/docs/cli)
* Python 3.x (若需要執行資料處理腳本)

### 2. 安裝依賴 (Install Dependencies)
```bash
# 下載專案依賴套件
flutter pub get

```

### 3. 設定 Firebase (Firebase Setup)

本專案依賴 Firebase，請確保你擁有對應的 Firebase 專案權限，或建立一個新專案。

1. 登入 Firebase:
```bash
firebase login

```


2. 設定專案別名 (Alias):
* 查看 `.firebaserc` 確認專案 ID，或執行 `flutterfire configure` 重新綁定你的專案。


3. 部署 Firestore 規則 (可選):
```bash
firebase deploy --only firestore:rules

```


*(詳細設定請參考專案內的 `FIRESTORE_SETUP.md`)*

### 4. 啟動 App (Run App)

```bash
# 啟動模擬器或連接實機後執行
flutter run

```

## 📂 專案結構說明 (Project Structure)

```text
strengthwise/
├── lib/                 # Flutter 核心程式碼 (UI, Logic)
├── assets/              # 靜態資源 (圖片, ICON)
├── scripts/             # (建議將 Python 檔移入此處)
│   ├── import_exercises.py  # 動作庫匯入腳本
│   └── fillNull.py          # 資料清洗腳本
├── firestore.rules      # Firestore 安全規則
├── firebase.json        # Firebase 專案配置
├── pubspec.yaml         # Dart 套件依賴清單
└── README.md            # 專案說明文件

```

## 🐍 資料庫維護 (Data Maintenance)

若需要初始化動作庫（Exercises），請使用 Python 腳本：

```bash
# 安裝必要的 Python 套件 (如 firebase-admin)
pip install firebase-admin

# 執行匯入
python import_exercises.py

```

## 📄 相關文件 (Docs)

* **部署指南**: 請參閱 `快速部署指南.md`
* **資料庫設定**: 請參閱 `FIRESTORE_SETUP.md`

## 🤝 貢獻指南 (Contributing)

1. Fork 本專案
2. 建立 Feature Branch (`git checkout -b feature/NewFeature`)
3. Commit 修改 (`git commit -m 'Add NewFeature'`)
4. Push 到 Branch (`git push origin feature/NewFeature`)
5. 建立 Pull Request

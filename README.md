# StrengthWise 💪

> 智慧型重訓追蹤應用 - 用數據驅動你的訓練進步

一個基於 Flutter 與 Firebase 打造的跨平台健身訓練記錄 App，讓你輕鬆管理訓練計劃、記錄每一組動作，並透過數據分析追蹤你的肌力成長。

[![Flutter](https://img.shields.io/badge/Flutter-3.16+-02569B?logo=flutter)](https://flutter.dev/)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-FFCA28?logo=firebase)](https://firebase.google.com/)
[![Dart](https://img.shields.io/badge/Dart-3.1+-0175C2?logo=dart)](https://dart.dev/)

---

## ✨ 核心功能

### 🏋️ 訓練管理
- **訓練計劃**：創建、編輯、刪除訓練計劃
- **訓練模板**：保存常用的訓練計劃為模板，快速創建新計劃
- **訓練執行**：實時記錄每一組的重量、次數、完成狀態
- **自動保存**：訓練過程中自動保存進度，不怕資料遺失

### 📊 數據記錄
- **完整記錄**：記錄每次訓練的詳細數據
- **訓練備註**：為每次訓練添加備註
- **歷史查詢**：查看過往的訓練記錄
- **統計分析**：（開發中）訓練頻率、訓練量趨勢、個人最佳記錄

### 💪 運動庫
- **豐富的運動庫**：內建數百種運動動作，涵蓋各大肌群
- **階層式瀏覽**：依運動類型、身體部位、動作分類輕鬆查找
- **自訂動作**：創建專屬的自訂動作
- **動作詳情**：查看動作說明和教學

### 🗓️ 行事曆
- **月曆視圖**：一眼看清所有訓練安排
- **快速創建**：點擊日期快速創建訓練計劃
- **進度追蹤**：查看已完成和未完成的訓練

---

## 🚀 快速開始

### 環境需求

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.16 或更高版本
- [Dart SDK](https://dart.dev/get-dart) 3.1 或更高版本
- [Firebase CLI](https://firebase.google.com/docs/cli)（用於部署規則）

### 安裝步驟

1. **Clone 專案**
   ```bash
   git clone https://github.com/yourusername/strengthwise.git
   cd strengthwise
   ```

2. **安裝依賴**
   ```bash
   flutter pub get
   ```

3. **設定 Firebase**
   - 在 [Firebase Console](https://console.firebase.google.com/) 創建新專案
   - 下載 `google-services.json`（Android）和 `GoogleService-Info.plist`（iOS）
   - 或執行 `flutterfire configure` 自動配置

4. **執行應用**
   ```bash
   flutter run
   ```

---

## 🏗️ 技術架構

### 技術棧

- **框架**：Flutter 3.16+
- **語言**：Dart 3.1+
- **後端**：Firebase (Auth, Firestore, Storage, Analytics)
- **狀態管理**：Provider (ChangeNotifier)
- **依賴注入**：GetIt (Service Locator Pattern)
- **本地儲存**：Hive、SharedPreferences

### 架構模式

採用 **MVVM + Clean Architecture**，確保代碼清晰、易於維護：

```
View (UI 層)
  ↓ Provider/Consumer
Controller (業務邏輯層)
  ↓ Service Interface
Service (資料存取層)
  ↓ Firestore/Firebase
Model (資料模型層)
```

### 專案結構

```
strengthwise/
├── lib/             # Flutter 核心程式碼
│   ├── models/      # 資料模型
│   ├── services/    # 服務層（資料存取）
│   ├── controllers/ # 控制器層（業務邏輯）
│   └── views/       # UI 層（頁面和元件）
├── scripts/         # Python 和 Dart 工具腳本
├── docs/            # 專案文檔
├── assets/          # 靜態資源
└── ...
```

---

## 📱 功能截圖

<!-- TODO: 添加應用截圖 -->

---

## 🛠️ 開發

### 開發環境設定

1. **安裝 Flutter**
   ```bash
   # 檢查環境
   flutter doctor
   ```

2. **設定 IDE**
   - 推薦使用 VS Code 或 Android Studio
   - 安裝 Flutter 和 Dart 插件

3. **運行測試**
   ```bash
   flutter test
   ```

### 開發規範

- **代碼風格**：遵循 Dart 官方風格指南
- **註解**：關鍵邏輯使用繁體中文註解
- **提交**：使用有意義的 commit message
- **測試**：確保新功能有對應的測試

詳細的開發規範請參考 [AGENTS.md](AGENTS.md)。

---

## 📂 資料庫結構

使用 **Firebase Firestore** 作為資料庫，主要集合：

| 集合 | 說明 |
|------|------|
| `users` | 用戶資料 |
| `workoutPlans` | 訓練計劃和記錄（統一） |
| `workoutTemplates` | 訓練模板 |
| `exercises` | 公共運動庫 |
| `customExercises` | 用戶自訂動作 |

詳細設計請參考 [docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md)。

---

## 📖 文檔

### 給開發者

- **[docs/PROJECT_OVERVIEW.md](docs/PROJECT_OVERVIEW.md)** - 專案架構和技術棧
- **[docs/DEVELOPMENT_STATUS.md](docs/DEVELOPMENT_STATUS.md)** - 當前開發進度
- **[docs/DATABASE_DESIGN.md](docs/DATABASE_DESIGN.md)** - 資料庫設計

### 給 AI Agent

- **[AGENTS.md](AGENTS.md)** - AI 開發指南
- **[docs/README.md](docs/README.md)** - 文檔導航
- **[docs/cursor_tasks/](docs/cursor_tasks/)** - 任務文檔

---

## 🗺️ 開發路線圖

### ✅ 已完成（v1.0）

- [x] 用戶登入/登出（Google Sign-In）
- [x] 訓練計劃管理（創建、編輯、刪除）
- [x] 訓練模板系統
- [x] 訓練執行和記錄
- [x] 運動庫瀏覽
- [x] 自訂動作功能
- [x] 行事曆視圖
- [x] 個人資料編輯

### 🚧 進行中（v1.1）

- [ ] 訓練統計功能
  - [ ] 訓練頻率統計
  - [ ] 訓練量趨勢圖表
  - [ ] 個人最佳記錄（PR）
  - [ ] 各肌群訓練分布

### 📅 計劃中（v2.0）

- [ ] 體重追蹤
- [ ] 體態照片記錄
- [ ] 身體圍度測量
- [ ] 數據匯出（CSV/PDF）
- [ ] 訓練提醒通知

### 🔮 未來計劃

- [ ] 教練-學員雙邊平台
- [ ] 預約系統
- [ ] 教學筆記
- [ ] 社交功能

---

## 🤝 貢獻

歡迎貢獻！請遵循以下步驟：

1. Fork 本專案
2. 創建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 開啟 Pull Request

### 貢獻指南

- 遵循專案的代碼風格
- 添加適當的測試
- 更新相關文檔
- 確保所有測試通過

---

## 📄 授權

本專案採用 MIT 授權 - 詳見 [LICENSE](LICENSE) 文件。

---

## 📞 聯繫方式

如有問題或建議，歡迎：

- 開 Issue
- 發 Pull Request
- 聯繫維護者

---

## 🙏 致謝

- [Flutter](https://flutter.dev/) - 優秀的跨平台框架
- [Firebase](https://firebase.google.com/) - 強大的後端服務
- 所有貢獻者和用戶的支持

---

**打造屬於你的健身訓練系統，從 StrengthWise 開始！** 💪

---

<div align="center">

Made with ❤️ by StrengthWise Team

[⬆ 回到頂部](#strengthwise-)

</div>

# StrengthWise - 專案總覽

> 專案架構、技術棧、目錄結構

**最後更新**：2026-02-09

---

## 📋 專案簡介

**StrengthWise** 是基於 Flutter 和 Supabase 的跨平台健身訓練追蹤應用。

| 項目 | 內容 |
|------|------|
| 當前版本 | v5.1（完成 - App 版本檢查）|
| 上一版本 | v5.0（動作分類系統 v2）|
| 主要功能 | 個人健身記錄 + 教練學員管理平台 |
| 目標平台 | Android / iOS / Windows / Web |

### 專案規模

```
總代碼量：~74,000 行
├── Flutter/Dart：~70,000 行
├── SQL/Migrations：~6,000 行（30+ 個檔案）
└── Python 腳本：~2,400 行

核心組件：
├── Pages：65+
├── Controllers：29（含 70+ 子模組）
├── Services：60+（含 Realtime、Notification）
├── Interfaces：25 Controller + 20+ Service
├── Models：74+
├── Widgets：240+（含 Coach Mark、v5.0 篩選元件）
└── Tests：390+（Service 單元測試 + 版本工具）
```

---

## 🛠️ 技術棧

### 前端

```
Flutter (Dart SDK >=3.1.0, Flutter >=3.16.0)
├── 狀態管理：Provider (ChangeNotifier)
├── 依賴注入：GetIt (Service Locator)
├── 圖表庫：fl_chart
├── 字體：Inter (UI) + JetBrains Mono (數據)
└── 設計系統：Material 3 + Kinetic Design
```

### 後端

```
Supabase (PostgreSQL 14+)
├── Authentication：Supabase Auth + Google Sign-In
├── Database：PostgreSQL（29 個表格，含 v5.0 參照表 + v5.1 app_config）
├── Storage：檔案儲存（照片、手繪圖）
├── Realtime：即時訂閱
└── 安全性：Row Level Security (RLS) - 50+ 策略
```

---

## 🏗️ 架構設計

### MVVM + Clean Architecture

```
┌─────────────────────────────────────┐
│   View Layer (UI)                   │  ← lib/views/
│   - Pages, Widgets                  │
│   - 只負責顯示和用戶互動              │
└──────────────┬──────────────────────┘
               │ Provider/Consumer
┌──────────────▼──────────────────────┐
│   Controller Layer (ViewModel)      │  ← lib/controllers/
│   - Business Logic                  │
│   - ChangeNotifier                  │
└──────────────┬──────────────────────┘
               │ Service Interface
┌──────────────▼──────────────────────┐
│   Service Layer (Repository)        │  ← lib/services/
│   - Data Access                     │
│   - Supabase Operations             │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Model Layer                       │  ← lib/models/
│   - fromSupabase() / toMap()        │
└─────────────────────────────────────┘
```

### 依賴注入策略

| 層級 | 註冊方式 | 生命週期 |
|------|---------|----------|
| Service | `LazySingleton` | 首次使用時創建 |
| Controller | `Factory` | 每次請求創建 |
| Utility | `Singleton` | 立即創建 |

```dart
// ✅ 正確：透過 Interface
final workoutService = serviceLocator<IWorkoutService>();

// ❌ 錯誤：直接使用實作
final service = WorkoutServiceSupabase();
```

### 效能指標

| 指標 | 目標 |
|------|------|
| 應用啟動 | <200ms |
| 統計頁面 | <5ms（快取）|
| Frames Skip | <30 |

---

## 📂 目錄結構

```
lib/
├── main.dart                    # 應用入口
├── models/                      # 資料模型
│   ├── user_model.dart
│   ├── workout_record_model.dart
│   ├── health_assessment/       # 健康評估模型
│   └── session_note/            # 課程筆記模型
├── services/                    # 服務層
│   ├── interfaces/              # 服務介面（必須）
│   ├── locator/                 # 依賴注入容器
│   ├── realtime/                # Supabase Realtime ⭐ v3.1
│   └── supabase/                # Supabase 實作
├── controllers/                 # 控制器層
│   ├── interfaces/              # 控制器介面
│   └── workout_execution/       # 訓練執行子模組
├── common_widgets/              # 通用組件 ⭐ v3.8
│   ├── time_picker/             # 時間選擇器
│   ├── cards/                   # 通用卡片
│   └── loading/                 # 載入狀態
├── views/                       # UI 層
│   ├── pages/                   # 頁面（按功能分類）
│   │   ├── auth/                # 認證
│   │   ├── exercises/           # 運動庫
│   │   ├── home/                # 首頁
│   │   ├── notes/               # 視覺化筆記
│   │   ├── profile/             # 個人資料
│   │   ├── readiness/           # 課前問卷 ⭐ v3.0
│   │   ├── relationships/       # 教練學員系統
│   │   ├── scheduling/          # 預約系統
│   │   ├── session/             # Session Mode ⭐ v3.0
│   │   ├── statistics/          # 統計分析
│   │   └── workout/             # 訓練系統
│   ├── painters/                # Canvas Painter
│   └── shared/                  # 共用組件
├── themes/                      # 主題系統
└── utils/                       # 工具類

migrations/                      # SQL Migration（29+ 個）
docs/                            # 文檔
scripts/                         # Python 工具
```

---

## ⚙️ 開發流程

### 新增功能標準流程

```
1. 設計 Model（fromSupabase + toMap）
2. 創建 Service Interface
3. 實作 Service（Supabase）
4. 註冊到 Service Locator
5. 創建 Controller（ChangeNotifier）
6. 建立 UI（Provider）
7. 測試
```

### 核心規範

| 規範 | 說明 |
|------|------|
| 型別安全 | 透過 Model 類別操作資料庫 |
| 依賴注入 | 透過 Interface 使用服務 |
| 狀態管理 | Controller + ChangeNotifier |
| 錯誤處理 | ErrorHandlingService |
| 語言 | 繁體中文（UI + 註解）|

詳見：`.cursor/rules/` - AI 開發規範

---

## 📚 相關文檔

- [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) - 開發狀態
- [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) - 資料庫設計
- [AGENTS.md](../AGENTS.md) - 完整開發規範

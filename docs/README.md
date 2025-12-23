# StrengthWise - 文檔導航

> 專案文檔總覽，幫助快速找到需要的資訊

**最後更新**：2024年12月23日（文檔已整合到核心文檔）

---

## 📚 核心文檔

### 1. [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - 專案總覽
**必讀** - 了解專案的技術架構、開發規範、核心概念

**包含內容**：
- 專案簡介和定位
- 技術棧（Flutter + Firebase）
- MVVM + Clean Architecture 架構
- 目錄結構
- 開發規範（型別安全、依賴注入、錯誤處理）
- 命名規範
- 常見問題排查

**適合**：新加入的開發者、需要了解整體架構時

---

### 2. [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) - 開發狀態
**常用** - 查看當前進度、已完成功能、下一步計劃

**包含內容**：
- 當前開發目標
- 已完成功能列表（v1.0）
- 重要 Bug 修復記錄
- 資料庫架構改進
- 待完成功能
- 開發時間線
- 下一步行動

**適合**：日常開發、了解進度、規劃工作

---

### 3. [DATABASE_DESIGN.md](DATABASE_DESIGN.md) - 資料庫設計
**參考** - Firestore 資料庫結構和查詢策略

**包含內容**：
- 集合總覽
- 每個集合的詳細結構
- 索引設計
- 常用查詢模式
- 性能優化策略
- 注意事項

**適合**：實作新功能、查詢資料庫、優化性能時

---

### 4. [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md) - 統計功能實作
**目標** - 下一步開發計劃

**包含內容**：
- 統計功能需求
- 實作計劃（3 階段）
- 需要的套件（fl_chart）
- UI 設計草圖
- 查詢策略
- 驗收標準

**適合**：開始開發統計功能時

---

## 🔧 配置與設定

### 環境配置
- **[SETUP.md](SETUP.md)** - 完整環境配置指南
  - Flutter 環境安裝
  - Firebase 專案設定
  - 開發工具配置
  - 常見問題解決

### Firebase 設定
- **[FIREBASE_AUTH_SETUP.md](FIREBASE_AUTH_SETUP.md)** - Firebase 認證設定
- **[FIRESTORE_SETUP.md](FIRESTORE_SETUP.md)** - Firestore 資料庫設定

---

## 📊 最近更新（2024-12-23）

### 資料庫升級
所有資料庫相關的更新已整合到核心文檔：

- **[DATABASE_DESIGN.md](DATABASE_DESIGN.md)** - 查看完整的資料庫設計
  - ✅ 動作分類系統升級（794 個動作）
  - ✅ 新增專業 5 層分類結構
  - ✅ 身體部位數據清理（合併重複項）

- **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 查看開發進度
  - ✅ 新動作瀏覽 UI 實作記錄
  - ✅ 資料庫架構改進記錄
  - ✅ Bug 修復記錄

### 相關腳本
執行資料庫遷移的腳本說明：

- **[scripts/README.md](../scripts/README.md)** - 所有腳本的使用說明
  - `analyze_body_parts.py` - 身體部位分析
  - `merge_body_parts.py` - 身體部位合併
  - `reclassify_exercises.py` - 動作重新分類
  - `update_exercise_classification.py` - 更新分類到 Firestore

---

## 🗂️ 歸檔文檔

### [archive/](archive/) - 歷史記錄

- **[CLEANUP_NOTES.md](archive/CLEANUP_NOTES.md)** - 清理筆記
- 其他過時或已完成的文檔

---

## 📁 完整文檔結構

```
docs/
├── README.md                              ← 你在這裡（文檔導航）
│
├── 核心文檔
│   ├── PROJECT_OVERVIEW.md                ← 專案總覽（技術架構）
│   ├── DEVELOPMENT_STATUS.md              ← 開發狀態（包含最新更新記錄）
│   ├── DATABASE_DESIGN.md                 ← 資料庫設計（包含新分類結構）
│   └── STATISTICS_IMPLEMENTATION.md       ← 統計功能實作指南
│
├── 配置文檔
│   ├── SETUP.md                           ← 環境配置指南
│   ├── FIREBASE_AUTH_SETUP.md             ← Firebase 認證設定
│   └── FIRESTORE_SETUP.md                 ← Firestore 設定
│
├── archive/                               ← 歷史歸檔
│   ├── CLEANUP_NOTES.md                   ← 清理筆記
│   └── DOCS_ORGANIZATION_SUMMARY.md       ← 文檔整理報告
│
└── cursor_tasks/                          ← 雙邊平台任務（暫停）
    ├── 00_PROJECT_CONTEXT.md              ← 專案背景
    ├── 01_TASK_DB_REFACTOR.md             ← 資料庫重構
    ├── 02_TASK_RELATIONSHIPS.md           ← 教練-學員綁定
    ├── 03_TASK_BOOKING.md                 ← 預約系統
    └── 04_TASK_TEACHING.md                ← 教學筆記
```

**注意**：所有資料庫遷移和 UI 更新的詳細記錄已整合到核心文檔中：
- 資料庫相關 → `DATABASE_DESIGN.md` 和 `DEVELOPMENT_STATUS.md`
- UI 更新 → `DEVELOPMENT_STATUS.md`
- 腳本說明 → `../scripts/README.md`

---

## 🎯 快速導航

### 我想...

#### 了解專案整體架構
→ 閱讀 `PROJECT_OVERVIEW.md`

#### 知道當前開發到哪裡
→ 閱讀 `DEVELOPMENT_STATUS.md`

#### 查詢資料庫結構
→ 閱讀 `DATABASE_DESIGN.md`

#### 開始開發統計功能
→ 閱讀 `STATISTICS_IMPLEMENTATION.md`

#### 實作新功能
1. 先讀 `PROJECT_OVERVIEW.md`（了解規範）
2. 再讀 `DATABASE_DESIGN.md`（設計數據結構）
3. 參考 `DEVELOPMENT_STATUS.md`（確認不衝突）

#### 修復 Bug
1. 參考 `DEVELOPMENT_STATUS.md` 的「Bug 修復記錄」
2. 查看 `PROJECT_OVERVIEW.md` 的「常見問題排查」

#### 優化性能
→ 參考 `DATABASE_DESIGN.md` 的「性能優化策略」

#### 查看最近的資料庫變更
→ 查看 `DATABASE_DESIGN.md`（exercises 和 bodyParts 集合說明）
→ 查看 `DEVELOPMENT_STATUS.md`（資料庫架構改進章節）

#### 查看最近的 UI 更新
→ 查看 `DEVELOPMENT_STATUS.md`（運動庫管理章節）

#### 設定開發環境
→ 閱讀 `SETUP.md`

---

## 📝 文檔維護規範

### 更新時機
- **DEVELOPMENT_STATUS.md**：每完成一個功能/修復一個 Bug
- **DATABASE_DESIGN.md**：每次修改資料庫結構
- **PROJECT_OVERVIEW.md**：很少更新（只在架構變更時）
- **STATISTICS_IMPLEMENTATION.md**：統計功能開發期間

### 更新方式
1. 直接編輯 Markdown 檔案
2. 更新「最後更新」日期
3. 提交 git commit

### 文檔整合原則
- **資料庫相關更新** → 整合到 `DATABASE_DESIGN.md` 和 `DEVELOPMENT_STATUS.md`
- **UI 功能更新** → 整合到 `DEVELOPMENT_STATUS.md`
- **腳本使用說明** → 整合到 `../scripts/README.md`
- **過時文檔** → 移到 `archive/`

---

## 🔗 外部資源

### 專案相關
- [Flutter 官方文檔](https://flutter.dev/docs)
- [Firebase 官方文檔](https://firebase.google.com/docs)
- [Provider 套件](https://pub.dev/packages/provider)
- [GetIt 套件](https://pub.dev/packages/get_it)

### UI 相關
- [fl_chart 文檔](https://pub.dev/packages/fl_chart)
- [Material Design](https://material.io/design)

---

## 💬 問題與反饋

如果文檔有任何問題、建議或需要補充的內容，請：
1. 直接編輯對應的 Markdown 檔案
2. 或在開發會議中提出

---

## 🎉 最近更新（2024-12-23）

### ✅ 文檔整合完成
- 將資料庫遷移記錄整合到 `DATABASE_DESIGN.md`
- 將 UI 更新記錄整合到 `DEVELOPMENT_STATUS.md`
- 簡化文檔結構，只保留核心文檔
- 所有詳細資訊都在核心文檔中可查

### ✅ 資料庫升級
- **動作分類系統升級**：794 個動作重新分類（詳見 `DATABASE_DESIGN.md`）
- **身體部位數據清理**：合併重複項目（詳見 `DATABASE_DESIGN.md`）
- **新 UI 實作**：5 層分類導航系統（詳見 `DEVELOPMENT_STATUS.md`）

---

**開始開發前，建議先閱讀 `PROJECT_OVERVIEW.md` 和 `DEVELOPMENT_STATUS.md`！**

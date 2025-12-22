# StrengthWise - 文檔導航

> 專案文檔總覽，幫助快速找到需要的資訊

**最後更新**：2024年12月22日

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

## 🔧 輔助文檔

### 配置與設定
- **[FIREBASE_AUTH_SETUP.md](FIREBASE_AUTH_SETUP.md)** - Firebase 認證設定
- **[FIRESTORE_SETUP.md](FIRESTORE_SETUP.md)** - Firestore 資料庫設定
- **[README_環境設置.md](README_環境設置.md)** - 完整環境配置指南

### AI 開發指南
- **[AGENTS.md](../AGENTS.md)** - AI 助手開發指南
- 完整的開發規範和技術細節

---

## 📁 文檔結構

```
docs/
├── README.md                       ← 你在這裡
├── PROJECT_OVERVIEW.md             ← 專案總覽（技術架構）
├── DEVELOPMENT_STATUS.md           ← 開發狀態（當前進度）
├── DATABASE_DESIGN.md              ← 資料庫設計（Firestore）
├── STATISTICS_IMPLEMENTATION.md    ← 統計功能實作指南
└── cursor_tasks/                   ← 雙邊平台任務（暫停）
    ├── 02_TASK_RELATIONSHIPS.md   # 教練-學員綁定
    ├── 03_TASK_BOOKING.md         # 預約系統
    └── 04_TASK_TEACHING.md        # 教學筆記
```

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
→ 先讀 `PROJECT_OVERVIEW.md`（了解規範）
→ 再讀 `DATABASE_DESIGN.md`（設計數據結構）
→ 參考 `DEVELOPMENT_STATUS.md`（確認不衝突）

#### 修復 Bug
→ 參考 `DEVELOPMENT_STATUS.md` 的「Bug 修復記錄」
→ 查看 `PROJECT_OVERVIEW.md` 的「常見問題排查」

#### 優化性能
→ 參考 `DATABASE_DESIGN.md` 的「性能優化策略」

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

**開始開發前，建議先閱讀 `PROJECT_OVERVIEW.md` 和 `DEVELOPMENT_STATUS.md`！**


# StrengthWise - 文檔導航

> 快速找到你需要的文檔

**最後更新**：2024年12月26日

---

## 🚀 快速開始

### 新手開發者
1. **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - 專案架構和技術棧（必讀 ⭐）
2. **[DATABASE_SUPABASE.md](DATABASE_SUPABASE.md)** - 資料庫設計（必讀 ⭐）
3. **[../AGENTS.md](../AGENTS.md)** - AI 開發指南和規範
4. 查看 `lib/views/pages/` 的簡單頁面開始

### 維護開發者
1. **[DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 當前開發狀態和下一步任務
2. **[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md)** - 架構總覽
3. 查看已知問題列表
4. 參考現有代碼進行修改

### UI/UX 設計
1. **[UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)** - 完整設計規範（20,000+ 字）
2. **[ui_prototype.html](ui_prototype.html)** - 互動原型
3. Material 3 + Kinetic Design System

---

## 📚 文檔分類

### 🎯 核心文檔（必讀）

| 文檔 | 說明 | 優先級 |
|------|------|--------|
| [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) | 專案架構、技術棧、開發規範 | ⭐⭐⭐ |
| [DATABASE_SUPABASE.md](DATABASE_SUPABASE.md) | Supabase PostgreSQL 資料庫設計 | ⭐⭐⭐ |
| [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) | 當前開發狀態、已知問題、下一步計劃 | ⭐⭐ |
| [UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md) | Kinetic 設計系統、Material 3 規範 | ⭐⭐ |

### 📖 功能文檔

| 文檔 | 說明 |
|------|------|
| [STATISTICS_IMPLEMENTATION.md](STATISTICS_IMPLEMENTATION.md) | 統計功能實作指南 |

### 🔧 操作指南

| 文檔 | 說明 |
|------|------|
| [BUILD_RELEASE.md](BUILD_RELEASE.md) | Release APK 構建和安裝 |
| [GOOGLE_SIGNIN_COMPLETE_SETUP.md](GOOGLE_SIGNIN_COMPLETE_SETUP.md) | Google Sign-In 完整配置 |

---

## 🗂️ 文檔結構

```
docs/
├── README.md                           # 本文件（文檔導航）
│
├── 核心文檔
│   ├── PROJECT_OVERVIEW.md             # ⭐ 專案架構總覽
│   ├── DATABASE_SUPABASE.md            # ⭐ Supabase 資料庫設計
│   ├── DEVELOPMENT_STATUS.md           # 開發狀態和計劃
│   └── UI_UX_GUIDELINES.md             # UI/UX 設計規範
│
├── 功能文檔
│   └── STATISTICS_IMPLEMENTATION.md    # 統計功能實作
│
├── 操作指南
│   ├── BUILD_RELEASE.md                # 構建指南
│   └── GOOGLE_SIGNIN_COMPLETE_SETUP.md # Google 登入配置
│
├── 互動原型
│   └── ui_prototype.html               # HTML 互動原型
│
└── 任務文檔（暫停）
    └── cursor_tasks/                   # 雙邊平台任務
```

---

## 🔍 常見問題

### Q1: 我應該從哪個文檔開始？
- **新手**：先讀 `PROJECT_OVERVIEW.md`，了解專案架構
- **維護者**：先讀 `DEVELOPMENT_STATUS.md`，了解當前狀態
- **設計師**：先讀 `UI_UX_GUIDELINES.md`，了解設計系統

### Q2: 資料庫文檔在哪？
- **當前版本**：`DATABASE_SUPABASE.md`（Supabase PostgreSQL）
- **舊版本**：`archive/DATABASE_DESIGN.md`（Firestore，已淘汰）

### Q3: 如何了解專案當前進度？
閱讀 `DEVELOPMENT_STATUS.md`，包含：
- ✅ 已完成功能
- ⏳ 當前任務
- 📋 下一步計劃
- 🐛 已知問題

### Q4: UI/UX 設計規範在哪？
`UI_UX_GUIDELINES.md` 包含：
- Kinetic 設計系統
- Material 3 規範
- 配色方案（Titanium Blue）
- 字體系統（Inter + JetBrains Mono）
- 間距系統（8 點網格）

### Q5: 如何構建 Release APK？
參考 `BUILD_RELEASE.md`，包含：
- 構建步驟
- 簽名配置
- 安裝測試
- 常見問題

---

## 📝 文檔維護規範

### 更新頻率
- **核心文檔**：重大變更時更新
- **開發狀態**：每日/每週更新
- **操作指南**：流程變更時更新

### 文檔規範
- ✅ 使用繁體中文
- ✅ Markdown 格式
- ✅ 清晰的標題結構
- ✅ 代碼範例使用語法高亮
- ✅ 更新時修改「最後更新」日期

### 文檔管理
- ❌ 避免創建重複文檔
- ✅ 整合相似內容
- ✅ 過時文檔移至 `archive/`
- ✅ 保持文檔導航最新

---

## 🔗 相關資源

### 專案文檔
- **AI 開發指南**：`../AGENTS.md`（根目錄）
- **專案首頁**：`../README.md`（根目錄）

### 代碼結構
- **Models**：`../lib/models/`
- **Services**：`../lib/services/`
- **Controllers**：`../lib/controllers/`
- **Views**：`../lib/views/`
- **Themes**：`../lib/themes/`

### 資料庫遷移
- **SQL 腳本**：`../migrations/`

### 輔助腳本
- **腳本說明**：`../scripts/README.md`

---

## 🎯 快速查找

### 架構相關
- 專案架構 → `PROJECT_OVERVIEW.md`
- 資料庫設計 → `DATABASE_SUPABASE.md`
- 依賴注入 → `PROJECT_OVERVIEW.md` → 依賴注入策略

### 開發相關
- 開發規範 → `PROJECT_OVERVIEW.md` → 開發規範
- 開發狀態 → `DEVELOPMENT_STATUS.md`
- 已知問題 → `DEVELOPMENT_STATUS.md` → 已知問題

### UI/UX 相關
- 設計系統 → `UI_UX_GUIDELINES.md`
- 配色方案 → `UI_UX_GUIDELINES.md` → 配色系統
- 互動原型 → `ui_prototype.html`

### 操作相關
- 構建 APK → `BUILD_RELEASE.md`
- Google 登入 → `GOOGLE_SIGNIN_COMPLETE_SETUP.md`
- 統計功能 → `STATISTICS_IMPLEMENTATION.md`

---

**提示**：文檔持續更新中，有任何建議歡迎提出！

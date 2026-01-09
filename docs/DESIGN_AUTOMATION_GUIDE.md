# 設計自動化指南 - D2 架構圖 + Slidev 簡報

> AI Agent 可讀的設計工具安裝與使用指南

**最後更新**：2026-01-08

---

## 📋 概述

本指南涵蓋兩個設計自動化工具：

| 工具 | 用途 | 輸出格式 |
|------|------|---------|
| **D2** | 架構圖、流程圖 | SVG, PNG |
| **Slidev** | 技術簡報 | HTML, PDF |

---

## 🛠️ 安裝指南

### 1. D2 (Declarative Diagramming)

**Windows (PowerShell)**
```powershell
winget install d2
```

**macOS**
```bash
brew install d2
```

**Linux**
```bash
curl -fsSL https://d2lang.com/install.sh | sh -s --
```

**驗證安裝**
```bash
d2 --version
```

---

### 2. Slidev

**前置條件**：Node.js 18+

**驗證 Node.js**
```bash
node --version
```

**如需安裝 Node.js**
```powershell
# Windows
winget install OpenJS.NodeJS.LTS

# macOS
brew install node

# Linux
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y nodejs
```

---

## 📊 D2 使用指南

### 檔案位置

```
docs/diagrams/
├── *.d2          # D2 原始碼
├── *.svg         # 輸出 SVG
└── *.png         # 輸出 PNG
```

### 生成架構圖

**基本渲染**
```bash
d2 input.d2 output.svg
```

**手繪風格 (Sketch Mode)** ⭐ 推薦
```bash
d2 --sketch input.d2 output.svg
```

**指定佈局引擎**
```bash
d2 --layout elk input.d2 output.svg
```

**指定主題**
```bash
# 深色主題
d2 --theme 200 input.d2 output.svg

# 淺色主題
d2 --theme 1 input.d2 output.svg
```

**即時預覽 (Watch Mode)**
```bash
d2 --watch input.d2
```

### D2 語法範例

```d2
# 基本節點
user: User
api: API Server

# 連接
user -> api: Request

# 容器
backend: Backend {
  db: Database {
    shape: cylinder
  }
  cache: Redis
}

# 樣式
api -> backend.db: Query {
  style: {
    stroke: "#2563EB"
    stroke-width: 2
  }
}
```

### 專案現有架構圖

```bash
# 渲染 StrengthWise 架構圖
d2 --sketch docs/diagrams/strengthwise-architecture.d2 docs/diagrams/strengthwise-architecture.svg
```

---

## 🎯 Slidev 使用指南

### 檔案位置

```
presentations/
└── strengthwise-overview/
    ├── slides.md       # 簡報內容
    ├── package.json    # 依賴配置
    └── node_modules/   # 安裝後產生
```

### 初始化新簡報

```bash
# 方法 1：使用現有目錄
cd presentations/strengthwise-overview
npm install

# 方法 2：創建新簡報
npm init slidev@latest my-presentation
```

### 啟動開發伺服器

```bash
cd presentations/strengthwise-overview
npm run dev
# 或
npx slidev --open
```

**預設網址**
- 簡報：http://localhost:3030/
- 簡報者模式：http://localhost:3030/presenter/
- 總覽：http://localhost:3030/overview/

### 匯出 PDF

```bash
cd presentations/strengthwise-overview
npx slidev export --output output.pdf
```

**注意**：首次匯出會自動下載 Playwright (Chromium ~140MB)

### 匯出 PNG

```bash
npx slidev export --format png --output ./slides
```

### Slidev 快捷鍵

| 按鍵 | 功能 |
|------|------|
| `→` / `Space` | 下一頁 |
| `←` | 上一頁 |
| `o` | 總覽模式 |
| `d` | 深色/淺色切換 |
| `f` | 全螢幕 |
| `g` | 跳轉頁面 |

---

## 🎨 UI/UX Pro Max 搜尋

### 搜尋指令

```bash
# 搜尋產品類型建議
python .shared/ui-ux-pro-max/scripts/search.py "fitness health" --domain product

# 搜尋風格建議
python .shared/ui-ux-pro-max/scripts/search.py "professional minimal" --domain style

# 搜尋 Flutter 最佳實踐
python .shared/ui-ux-pro-max/scripts/search.py "theming cards" --stack flutter

# 搜尋配色建議
python .shared/ui-ux-pro-max/scripts/search.py "saas dashboard" --domain color

# 搜尋 UX 建議
python .shared/ui-ux-pro-max/scripts/search.py "contrast accessibility" --domain ux
```

### 可用 Domain

| Domain | 用途 |
|--------|------|
| `product` | 產品類型推薦 |
| `style` | UI 風格指南 |
| `color` | 配色方案 |
| `typography` | 字體搭配 |
| `chart` | 圖表類型 |
| `landing` | 著陸頁結構 |
| `ux` | UX 最佳實踐 |

### 可用 Stack

`html-tailwind`, `react`, `nextjs`, `vue`, `svelte`, `swiftui`, `react-native`, `flutter`

---

## 📐 設計規範摘要

### 淺色模式配色（PDF 友善）

| 用途 | Tailwind Class | Hex |
|------|---------------|-----|
| 背景 | `bg-white` / `bg-slate-50` | #FFFFFF / #F8FAFC |
| 主要文字 | `text-slate-800` | #1E293B |
| 次要文字 | `text-slate-600` | #475569 |
| 邊框 | `border-slate-200` | #E2E8F0 |
| 強調 | `text-blue-700` | #1D4ED8 |

### 對比度要求

- 正文：至少 **4.5:1**
- 大標題：至少 **3:1**
- 避免 `text-gray-400` 在淺色背景

### 卡片樣式

```html
<div class="p-6 bg-white rounded-2xl shadow-xl border-2 border-slate-200">
  <!-- 內容 -->
</div>
```

---

## 🔄 常用工作流程

### 生成專案架構圖

```bash
# 1. 編輯 D2 檔案
# docs/diagrams/strengthwise-architecture.d2

# 2. 渲染
d2 --sketch docs/diagrams/strengthwise-architecture.d2 docs/diagrams/strengthwise-architecture.svg

# 3. 查看
# 用瀏覽器開啟 SVG 檔案
```

### 製作技術簡報

```bash
# 1. 進入簡報目錄
cd presentations/strengthwise-overview

# 2. 安裝依賴（首次）
npm install

# 3. 啟動開發
npm run dev

# 4. 編輯 slides.md

# 5. 匯出 PDF
npx slidev export --output strengthwise-v3.1.pdf
```

---

## 📁 專案結構

```
strengthwise-dev/
├── docs/
│   ├── diagrams/
│   │   ├── strengthwise-architecture.d2    # D2 原始碼
│   │   ├── strengthwise-architecture.svg   # 手繪風格輸出
│   │   └── strengthwise-architecture-light.svg
│   └── DESIGN_AUTOMATION_GUIDE.md          # 本文檔
├── presentations/
│   └── strengthwise-overview/
│       ├── slides.md                       # 簡報內容
│       └── package.json
└── .shared/
    └── ui-ux-pro-max/
        └── scripts/
            └── search.py                   # UI/UX 搜尋工具
```

---

## ⚠️ 注意事項

1. **D2 PNG 輸出**：需要 Playwright (Chromium)，首次使用會自動下載
2. **Slidev 匯出**：同樣需要 Playwright
3. **Windows 終端**：PowerShell 不支援 `&&`，請用 `;` 分隔指令
4. **中文字體**：確保系統有安裝中文字體（如 Noto Sans CJK）

---

## 📚 相關資源

- [D2 官方文檔](https://d2lang.com/)
- [Slidev 官方文檔](https://sli.dev/)
- [Tailwind CSS](https://tailwindcss.com/)
- UI/UX Pro Max：`.shared/ui-ux-pro-max/`

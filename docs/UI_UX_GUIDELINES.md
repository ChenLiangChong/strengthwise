# StrengthWise UI/UX 設計規範 v2.0 (Pro Max)

> 融合高性能與極致美學的下一代健身應用設計系統

**版本**：2.0 (Pro Max)  
**最後更新**：2025年1月3日  
**狀態**：🚀 執行階段

---

## 📑 目錄

1. [設計願景與核心哲學](#1-設計願景與核心哲學)
2. [Kinetic 2.0 設計語言](#2-kinetic-20-設計語言)
3. [Pro Max 色彩系統](#3-pro-max-色彩系統)
4. [排版與佈局 (Bento Grid)](#4-排版與佈局-bento-grid)
5. [組件庫與微互動](#5-組件庫與微互動)
6. [資料視覺化 (Charts)](#6-資料視覺化-charts)
7. [深色模式與環境適應](#7-深色模式與環境適應)

---

## 1. 設計願景與核心哲學

### 1.1 "Pro Max" 體驗
不僅僅是功能強大，更要讓使用者感受到**「精緻的工藝感」**。

- **Geometric Modern (幾何現代)**：採用 **Outfit** 字體，注入幾何與數位感，與傳統健身 App 區隔。
- **Energy Injection (能量注入)**：使用 **Magma Orange** 點綴冷靜的藍色系，激發訓練鬥志。
- **Glassmorphism (微玻璃擬態)**：在導航與浮動元素中使用高斯模糊 (Backdrop Filter)，營造通透的層次感。

### 1.2 使用者情境
- **專注模式 (Focus)**：訓練時，資訊極簡化，操作大尺寸化。
- **分析模式 (Analyze)**：回顧時，數據豐富化，圖表互動化。

---

## 2. Kinetic 2.0 設計語言

### 2.1 字體排印 (Typography)

引入雙字體策略：**Outfit** (標題) + **Work Sans / Inter** (內文)。

| 語意角色 | 字體 | 建議大小 | 字重 | 用途 |
|---------|------|---------|------|------|
| **Display Pro** | **Outfit** | 40sp | ExtraBold | 總訓練量破紀錄、主要行銷標題 |
| **Header** | **Outfit** | 28sp | Bold | 頁面大標題 (如 "Today's Status") |
| **Title** | **Outfit** | 20sp | SemiBold | 卡片標題 |
| **Body** | Inter / Work Sans | 16sp | Regular | 一般閱讀文字 |
| **Data Large** | JetBrains Mono | 24sp | Medium | 計時器、重量設定 (保持等寬特性) |

> **為什麼選擇 Outfit?**  
> Outfit 是一款受幾何形狀啟發的無襯線字體，具有現代、開放的特質，特別適合強調「科技健身」與「數據驅動」的品牌形象。

### 2.2 圖標系統 (Iconography)
全面採用 **Hugeicons** 或 **Phosphor Icons** 的 **Duotone (雙色調)** 風格，增加視覺豐富度。
- **線條寬度**：1.5pt (精緻感)
- **主色透明度**：100%
- **次色透明度**：30% (增加層次)

---

## 3. Pro Max 色彩系統

### 3.1 Titanium Blue & Magma Orange

基於健身應用分析，採用的 "Vibrant & Block-based" 配色方案。

#### 品牌漸層 (Brand Gradients)
- **Primary Gradient (Cold Power)**: `LinearGradient(topLeft, bottomRight, [#3B82F6, #2563EB])` (亮藍漸層) - 用於主要按鈕。
- **Accent Gradient (Heat Energy)**: `LinearGradient(topLeft, bottomRight, [#F97316, #EA580C])` (**Magma Orange**) - 用於 **PR 打破建議**、**燃脂區間**、**CTA 點擊**。

#### 基礎單色
- **Primary**: `#2563EB` (Royal Blue)
- **Accent / Energy**: `#FF6B35` (Magma Orange) - **[New]** 能量強調色
- **Secondary**: `#06B6D4` (Cyan)

### 3.2 表面與背景 (Surfaces)

#### 深色模式 (Dark Mode Pro)
不使用純黑，使用帶有藍色傾向的高級灰。

| 層級 | 顏色 (Hex) | 用途 |
|------|-----------|------|
| **Background** | `#0B1120` | App 底色 |
| **Surface 1** | `#162033` | 基礎卡片 (Bento Items) |
| **Surface 2** | `#1E293B` | 浮動卡片、模態窗 |
| **Glass** | `#1E293B` (opacity 0.7) | 導航列、Toast (需搭配 blur 20) |

---

## 4. 排版與佈局 (Bento Grid)

### 4.1 Bento Grid 原則 (Block-based Design)
將資訊模組化為大小不一的矩形區塊（便當盒），這是現代儀表板的標準配置。

- **Grid Gap**: 12dp 或 16dp
- **Corner Radius**: 24dp (更圓潤的 Super Ellipse 視覺感)
- **Layout**:
    - **2x2 Large**: 關鍵數據 (今日訓練)
    - **1x1 Small**: 快捷按鈕 (開始訓練、掃碼)
    - **2x1 Wide**: 趨勢圖表 (本週體重)

### 4.2 Flutter 實作建議
使用 `StaggeredGrid` 或 `Wrap` 配合 `LayoutBuilder` 實現響應式 Bento 佈局。

---

## 5. 組件庫與微互動

### 5.1 Glass Container (玻璃容器)
用於 `SliverAppBar` 背景或懸浮按鈕。

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      color: Theme.of(context).colorScheme.surface.withOpacity(0.7),
      // ... content
    ),
  ),
)
```

### 5.2 微互動 (Micro-interactions)
- **按鈕按壓**: Scale down to 0.96 (Duration: 100ms)
- **列表滑動**: 帶有彈性的 Overscroll 效果
- **Switch/Checkbox**: 狀態改變時的 morphing 動畫

---

## 6. 資料視覺化 (Charts)

使用 **fl_chart**，但樣式升級。

### 6.1 Line Chart (趨勢圖)
- **Line**: 使用曲線 (Curved)，寬度 3dp，帶有漸層色 (**Magma Orange** for Intensity, Blue for Volume)。
- **Below Bar**: 填充垂直漸層 (Primary Color with opacity 0.3 -> 0.0)，營造光暈感。

---

## 7. 深色模式與環境適應

### 7.1 強度適應 (Ambience Adaption)
在偵測到環境光極低時（如夜間健身房），自動切換至 "True Dark" (OLED Black) 以減少眩光。

### 7.2 高對比文字
在深色模式下，主要文字保持 `#F8FAFC` (Off-white)，次要文字 `#94A3B8` (Blue Grey)，確保至少 4.5:1 的對比度。

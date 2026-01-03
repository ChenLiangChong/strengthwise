# StrengthWise UI/UX 設計規範

> 從基礎功能到現代化設計系統的全面演進

**版本**：1.0  
**最後更新**：2024年12月25日  
**狀態**：🎨 設計階段

---

## 📑 目錄

1. [執行摘要與專案願景](#1-執行摘要與專案願景)
2. [健身應用程式介面設計現狀分析](#2-健身應用程式介面設計現狀分析)
3. [Kinetic 設計系統](#3-kinetic-設計系統)
4. [語意化色彩系統](#4-語意化色彩系統)
5. [核心視圖重塑方案](#5-核心視圖重塑方案)
6. [技術實作指南](#6-技術實作指南)
7. [互動設計與微動畫](#7-互動設計與微動畫)
8. [無障礙設計](#8-無障礙設計)
9. [執行路徑圖](#9-執行路徑圖)

---

## 1. 執行摘要與專案願景

### 1.1 設計目標

StrengthWise 的 UI/UX 重塑旨在建立一個**不僅美觀，且具備高度可用性與擴充性**的專業健身應用程式。

**核心戰略目標**：
- 🌓 **雙模主題系統**：Deep Dark / Clean Light
- 📝 **核心記錄體驗優化**：專注於 Logger 體驗，而非統計圖表
- 🎴 **卡片式設計**：提升資訊傳遞效率
- 🎨 **語意化色彩系統**：確保深淺模式無縫切換

### 1.2 設計哲學

> 優秀的健身 App UI 不僅是讓使用者「看見」數據，更是透過互動設計引導使用者進入「心流（Flow）」狀態，讓記錄訓練成為一種直覺且愉悅的儀式。

**適應性設計**：
- ☀️ **淺色模式**：適用於光線充足的商用健身房
- 🌙 **深色模式**：適用於昏暗的車庫健身房或夜間訓練
- 🔄 **系統跟隨**：自動適應使用者裝置設定

---

## 2. 健身應用程式介面設計現狀分析

### 2.1 競品介面模式分析

#### 現代健身 App 的設計趨勢

| 競品 | 核心特色 | 可借鏡之處 |
|------|---------|-----------|
| **Hevy** | 社群化佈局、動態卡片 | 每個 Set 的完成都有明確視覺回饋 |
| **Strong** | 極簡高對比深色模式 | 在低光源環境下的高對比度設計 |
| **Fitbod** | 預測性導航 | 自動聚焦未完成的 Set，減少點擊次數 |

### 2.2 訓練情境下的使用者需求

#### 生理狀態考量
使用者在訓練時通常處於：
- 💪 生理疲勞
- 🤚 手部顫抖、有汗
- ⏱️ 組間休息時間有限

#### 設計應對策略

**1. 菲茨定律（Fitts's Law）應用**
- ✅ 觸控目標最小高度：**48dp**
- ✅ 考慮採用全寬度滑動手勢替代小按鈕

**2. 掃視閱讀（Glanceability）**
- 📊 **運動名稱** > **重量/次數** > 歷史紀錄/備註
- 🔤 建立清晰的字體層級（Typography Hierarchy）

**3. 環境光適應**
- ☀️ **淺色模式**：抵抗眩光（戶外/明亮區域）
- 🌙 **深色模式**：省電（OLED）+ 避免刺眼（昏暗環境）

---

## 3. Kinetic 設計系統

> **Kinetic（動能）**：StrengthWise 的視覺語言核心

### 3.1 字體排印學（Typography）

#### 3.1.1 字體家族選擇

**雙字體策略**：區分「顯示層」與「數據層」

| 字體類型 | 推薦字體 | 應用場景 | 選擇理由 |
|---------|---------|---------|---------|
| **主要字體** | Inter / Manrope | 導航標題、按鈕、運動名稱、說明文案 | 高 x-height，小字號清晰可辨 |
| **數據字體** | JetBrains Mono / Roboto Mono | 重量輸入、次數顯示、計時器 | 等寬字體，數字不跳動，專業感 |

**⚠️ 關鍵設計決策**：
- 計時器使用等寬字體可防止 `09:59` → `10:00` 時的視覺跳動
- 等寬字體賦予介面精密儀表板的專業感

#### 3.1.2 字級系統表（Type Scale）

基於 **Material 3** 規範：

| 語意角色 | 字體 | 大小 | 字重 | 字母間距 | 應用範例 |
|---------|------|------|------|---------|---------|
| **Display Large** | Inter | 32sp | Bold (700) | -1.0% | 總訓練量、PR 慶祝 |
| **Headline Medium** | Inter | 24sp | SemiBold (600) | -0.5% | 頁面標題 ("Chest Day") |
| **Title Medium** | Inter | 18sp | Medium (500) | 0.15% | 動作名稱卡片標題 |
| **Body Large** | Inter | 16sp | Regular (400) | 0.5% | 一般說明文字 |
| **Body Medium** | Inter | 14sp | Regular (400) | 0.25% | 列表次要資訊 |
| **Label Large** | Manrope | 14sp | Medium (500) | 1.25% | 按鈕文字 (ALL CAPS) |
| **Data Large** | JetBrains Mono | 20sp | Medium (500) | 0% | 重量/次數輸入數值 |
| **Data Medium** | JetBrains Mono | 14sp | Regular (400) | 0% | 計時器、歷史數據 |

**⚠️ 深色模式特殊處理**：
- 過細字體（Light/Thin）在黑色背景會因**光暈效應（Halation）**而模糊
- 深色模式最小字重：**Regular (400)**

### 3.2 8點網格系統（8-Point Grid System）

> 專業 UI 設計的秩序基礎

#### 核心原則
所有元素的**尺寸、間距、留白**都必須是 **8 的倍數**（8, 16, 24, 32, 40...）

#### StrengthWise 間距規範

| 規範名稱 | 數值 | 應用場景 |
|---------|------|---------|
| **Container Padding** | 16dp | 標準頁面邊距 |
| **Card Spacing** | 12dp / 16dp | 卡片之間的垂直距離 |
| **Element Spacing** | 8dp | 圖示與文字之間的距離 |
| **Section Break** | 32dp | 不同區塊分隔（如「熱身組」與「正式組」） |
| **Touch Target** | 48dp | 按鈕最小高度，確保精準點擊 |
| **Micro Spacing** | 4dp | 極小間距（8 的半單位） |

#### Flutter 實作範例

```dart
// ✅ 正確：使用 8 的倍數
SizedBox(height: 16)
Padding(padding: EdgeInsets.all(16))
Container(height: 48) // 觸控目標

// ❌ 錯誤：隨意數值
Padding(padding: EdgeInsets.all(13))
```

### 3.3 圖標系統（Iconography）

#### 風格選擇
- **主要風格**：Outline（描邊），線條寬度 **1.5dp** 或 **2dp**
- **選中狀態**：Filled（實心）
- **推薦套件**：Hugeicons / Phosphor Icons

#### 功能性圖標清單

| 類別 | 圖標名稱 | 用途 |
|------|---------|------|
| **導航** | Home | 儀表板 |
| | Dumbbell | 動作庫 |
| | Calendar | 歷史紀錄 |
| | User | 個人檔案 |
| **操作** | Plus | 新增 |
| | Trash | 刪除 |
| | Copy | 複製組數 |
| | Timer | 休息計時 |
| **狀態** | Check-circle | 完成 |
| | Lock | 鎖定/付費功能 |
| | Flame | 連續紀錄 |

---

## 4. 語意化色彩系統

> 定義顏色的「功能」，而非「色相」

### 4.1 色彩角色定義（Color Roles）

基於 **Material 3** 規範：

| 角色名稱 | 用途 | 範例 |
|---------|------|------|
| **Primary** | 品牌識別色 | 「開始訓練」按鈕、選中的導航項目 |
| **On-Primary** | 主色之上的內容 | 按鈕內的文字/圖標（確保高對比） |
| **Container / Surface** | 表面色 | 卡片、對話框、底層紙張 |
| **Background** | 背景色 | App 最底層的畫布 |
| **Outline** | 輪廓色 | 輸入框邊框、分隔線 |
| **Success** | 成功色 | 完成組數、打破 PR |
| **Error** | 錯誤色 | 刪除、輸入錯誤 |
| **Warning** | 警告色 | 休息時間結束提醒 |

### 4.2 Titanium Blue 配色方案

#### 4.2.1 淺色模式（Light Mode）- 清晰、活力

適用於**日間或明亮健身房**，重點在於抵抗環境反光。

| Token 名稱 | 顏色描述 | Hex Code | 用途 |
|-----------|---------|----------|------|
| **primary** | 皇家藍 (Royal Blue) | `#2563EB` | 核心行動按鈕 |
| **onPrimary** | 純白 | `#FFFFFF` | 按鈕內文字 |
| **secondary** | 藍綠色 (Teal) | `#0D9488` | 輔助標示、進度條 |
| **background** | 冷灰白 (Cool Grey) | `#F1F5F9` | 頁面底色（非純白） |
| **surface** | 純白 | `#FFFFFF` | 卡片背景 |
| **onSurface** | 深藍灰 (Slate) | `#0F172A` | 主要閱讀文字 |
| **outline** | 淺灰 (Light Grey) | `#E2E8F0` | 卡片邊框 |
| **success** | 翡翠綠 (Emerald) | `#10B981` | 完成勾選 |

**🎨 設計洞察**：
- 背景色使用 `#F1F5F9` 而非純白，讓白色卡片能透過微弱陰影/邊框凸顯，形成**層次感**

#### 4.2.2 深色模式（Dark Mode）- 沉浸、專注

適用於**夜間或強調專注的訓練環境**，重點在於降低眼睛疲勞。

| Token 名稱 | 顏色描述 | Hex Code | 用途 |
|-----------|---------|----------|------|
| **primary** | 淺天藍 (Sky Blue) | `#60A5FA` | 降飽和處理，避免刺眼 |
| **onPrimary** | 深海藍 | `#0F172A` | 按鈕內文字 |
| **secondary** | 薄荷綠 (Mint) | `#5EEAD4` | 輔助標示 |
| **background** | 深岩灰 (Dark Slate) | `#0F172A` | 頁面底色（非純黑） |
| **surface** | 岩灰 (Slate) | `#1E293B` | 卡片背景 |
| **onSurface** | 灰白 (Off-White) | `#F8FAFC` | 主要閱讀文字（非純白） |
| **outline** | 深灰 (Dark Grey) | `#334155` | 卡片邊框 |
| **success** | 螢光綠 (Neon Green) | `#34D399` | 完成勾選 |

**🎨 設計洞察**：
1. **避免純黑**：除 OLED 省電外，純黑 `#000000` 會導致**拖影（Smearing）**，使用 `#0F172A` 提供柔和體驗
2. **色彩降飽和**：淺色模式的高飽和藍色在深色背景會產生「震動感」，深色模式主色需降低飽和度
3. **層次感（Elevation）**：深色模式用「表面疊加（Surface Overlay）」替代陰影——層級越高，背景越亮

---

## 5. 核心視圖重塑方案

### 5.1 儀表板視圖（Dashboard / Home View）

#### 目標
成為使用者的「**戰情中心**」，提供摘要與快速入口

#### UI 結構

**1. Header 區域**
```dart
SliverAppBar(
  expandedHeight: 120,
  flexibleSpace: FlexibleSpaceBar(
    title: Text('早安，[使用者名稱]'),
    // 背景可搭配低透明度幾何圖形裝飾
  ),
)
```

**2. 摘要卡片（Summary Cards）**
- 並排兩個卡片（`Row` > `Expanded` > `Card`）
- **左卡**：本週訓練次數
  - 大字號數字「**3**」（Display Large）
  - 下標「目標 4」（Body Medium）
- **右卡**：總負重
  - 大字號數字「**12,500**」（Display Large）
  - 下標「kg」（Body Medium）

**3. 快速開始（Quick Actions）**
- 全寬度卡片「**開始新的訓練**」
- 使用 Primary Color 作為背景
- 下方：「最近的訓練課表」水平滑動列表（`ListView.horizontal`）

### 5.2 訓練記錄視圖（Workout Logger View）⭐

> **靈魂核心**：使用者停留時間最長的頁面

#### UI 架構重構

**1. 頂部固定欄（Pinned Header）**
```dart
SliverAppBar(
  pinned: true,
  title: Column(
    children: [
      Text('Bench Press'), // 當前動作
      RestTimer(), // 休息計時器
    ],
  ),
)
```

**2. 卡片式動作組（Exercise Cards）**

每個動作封裝在獨立 `Card` 中：

```
┌─────────────────────────────────────┐
│ Bench Press                    ⋮    │ ← 卡片標題 + 菜單
├─────────────────────────────────────┤
│ Set | Previous | kg | Reps | ✓     │ ← 表頭
├─────────────────────────────────────┤
│  1  | 100×5    | [__] [__] [ ]     │ ← 輸入列
│  2  | 100×5    | [__] [__] [ ]     │
│  3  | 100×5    | [__] [__] [ ]     │
├─────────────────────────────────────┤
│         + Add Set                    │ ← 新增按鈕
└─────────────────────────────────────┘
```

**輸入列設計細節**：

| 欄位 | 設計 | 實作要點 |
|------|------|---------|
| **Set** | 灰色圓圈背景 + 序號 | 純展示，不可編輯 |
| **Previous** | 灰色斜體「100×5」 | 僅供參考，不可編輯 |
| **kg / Reps** | 圓角矩形 TextFormField | - 移除底線<br>- 淺色模式：淺灰背景<br>- 深色模式：深灰背景<br>- 字體：JetBrains Mono<br>- `keyboardType: TextInputType.numberWithOptions(decimal: true)` |
| **Check** | 巨大觸控區（48dp） | - 未完成：灰色空心方塊<br>- 完成：Primary Color 實心方塊<br>- 觸發 `HapticFeedback.mediumImpact()` |

**3. 空狀態處理（Empty States）**
- 預填（Pre-fill）上一組的數據
- 使用「幽靈文字（Ghost Text）」顯示建議數值

### 5.3 動作庫視圖（Exercise Library View）

#### 目標
從純文字列表升級為**視覺化動作百科**

#### 列表項目設計

```
┌─────────────────────────────────────┐
│ [B] Bench Press             i       │ ← Avatar + 名稱 + Info
│     Chest • Barbell                 │ ← 肌群標籤
├─────────────────────────────────────┤
│ [D] Deadlift                i       │
│     Back • Barbell                  │
└─────────────────────────────────────┘
```

- **左側**：動作首字母彩色圓形 Avatar（無圖片時）
- **中間**：動作名稱（Title）+ 肌群標籤（Subtitle）
- **右側**：Info 圖標，點擊展開詳細說明

#### 篩選器（Filter Chips）

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      ChoiceChip(label: Text('胸部'), selected: true),
      ChoiceChip(label: Text('背部'), selected: false),
      ChoiceChip(label: Text('腿部'), selected: false),
    ],
  ),
)
```

- 選中：Primary Color
- 未選中：Outline 風格

#### 搜尋體驗
- **即時過濾**功能
- 搜尋欄背景在深色模式下比背景稍亮
- 圓角（Stadium Border）

### 5.4 設定與主題視圖（Settings View）

#### 主題切換器（Theme Toggler）

使用 **SegmentedButton**（Material 3 新元件）：

```dart
SegmentedButton<ThemeMode>(
  segments: [
    ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.wb_sunny)),
    ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.nightlight_round)),
    ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android)),
  ],
  selected: {currentThemeMode},
  onSelectionChanged: (Set<ThemeMode> newSelection) {
    // 切換主題
  },
)
```

**選項**：
- ☀️ **Light**（太陽圖標）
- 🌙 **Dark**（月亮圖標）
- 📱 **System**（手機圖標，自動跟隨系統）

**預覽功能**：
- 切換時 App 應立即無縫轉換（`AnimatedTheme`）

---

## 6. 技術實作指南

### 6.1 主題資料結構（app_theme.dart）

創建獨立類別管理主題，保持 `main.dart` 乾淨。

#### 完整範例架構

```dart
import 'package:flutter/material.dart';

class AppTheme {
  // ========================================
  // 色彩種子定義
  // ========================================
  static const _lightSeed = Color(0xFF2563EB); // 皇家藍
  static const _darkSeed = Color(0xFF60A5FA);  // 淺天藍

  // ========================================
  // 淺色主題配置
  // ========================================
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    
    // 色彩方案
    colorScheme: ColorScheme.fromSeed(
      seedColor: _lightSeed,
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),     // 卡片背景（純白）
      background: const Color(0xFFF1F5F9),  // App 背景（冷灰白）
      onSurface: const Color(0xFF0F172A),   // 文字（深藍灰）
      outline: const Color(0xFFE2E8F0),     // 邊框（淺灰）
      error: const Color(0xFFEF4444),       // 錯誤（紅色）
    ),
    
    // Scaffold 背景
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    
    // 卡片主題（現代化平面設計）
    cardTheme: CardTheme(
      elevation: 0, // 移除陰影
      color: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE2E8F0), // 淺灰邊框
          width: 1,
        ),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    
    // AppBar 主題
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      foregroundColor: Color(0xFF0F172A),
      titleTextStyle: TextStyle(
        color: Color(0xFF0F172A),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    
    // 輸入框主題（全域統一）
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
    ),
    
    // 按鈕主題
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48), // 觸控目標
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );

  // ========================================
  // 深色主題配置
  // ========================================
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    
    // 色彩方案
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkSeed,
      brightness: Brightness.dark,
      surface: const Color(0xFF1E293B),     // 深岩灰卡片
      background: const Color(0xFF0F172A),  // 更深的背景
      onSurface: const Color(0xFFF8FAFC),   // 灰白文字
      outline: const Color(0xFF334155),     // 深灰邊框
      error: const Color(0xFFEF4444),
    ),
    
    // Scaffold 背景
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    
    // 卡片主題
    cardTheme: CardTheme(
      elevation: 0,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none, // 深色模式不需邊框
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    
    // AppBar 主題
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0F172A),
      elevation: 0,
      foregroundColor: Color(0xFFF8FAFC),
      titleTextStyle: TextStyle(
        color: Color(0xFFF8FAFC),
        fontWeight: FontWeight.bold,
        fontSize: 20,
      ),
    ),
    
    // 輸入框主題
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF334155), // 比卡片稍亮
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 16,
      ),
    ),
    
    // 按鈕主題
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
```

### 6.2 狀態管理與持久化

#### 架構層次

```
UI Layer (SettingsPage)
    ↓
State Layer (ThemeProvider / ThemeNotifier)
    ↓
Persistence Layer (ThemeService)
    ↓
Local Storage (SharedPreferences)
```

#### ThemeService 實作範例

```dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class ThemeService {
  static const String _themeKey = 'theme_mode';
  
  /// 從本地存儲讀取主題模式
  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(_themeKey) ?? 'system';
    
    switch (themeModeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// 保存主題模式到本地存儲
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString = 'system';
    
    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      case ThemeMode.system:
        themeModeString = 'system';
        break;
    }
    
    await prefs.setString(_themeKey, themeModeString);
  }
}
```

#### ThemeProvider 實作範例

```dart
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  final ThemeService _themeService;
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeProvider(this._themeService) {
    _loadTheme();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  /// 從本地存儲加載主題
  Future<void> _loadTheme() async {
    _themeMode = await _themeService.getThemeMode();
    notifyListeners();
  }
  
  /// 切換主題並保存
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _themeService.setThemeMode(mode);
    notifyListeners();
  }
}
```

#### MaterialApp 整合

```dart
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(ThemeService()),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'StrengthWise',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: HomePage(),
          );
        },
      ),
    );
  }
}
```

### 6.3 響應式佈局（Responsive Layout）

#### 核心原則

雖然健身 App 多為直屏使用，但手機尺寸差異巨大（iPhone SE → Foldable）。

#### 必須遵守的規範

**1. SafeArea 包裹**
```dart
Scaffold(
  body: SafeArea(
    child: YourContent(),
  ),
)
```

**2. Flexible/Expanded 使用**
```dart
Row(
  children: [
    Text('Set 1'),
    Flexible(
      child: TextFormField(), // 自動適應剩餘空間
    ),
  ],
)
```

**3. 避免固定寬度**
```dart
// ❌ 錯誤：固定寬度可能導致小螢幕溢出
Container(width: 350, child: Card())

//✅ 正確：使用百分比或 padding
Padding(
  padding: EdgeInsets.symmetric(horizontal: 16),
  child: Card(),
)
```

### 6.4 統一卡片組件（UnifiedSlotCard）

> **設計原則**：保持 Material Design 3 的 ListTile 默認樣式，統一視覺語言

#### 組件說明

`UnifiedSlotCard` 用於顯示時間時段資訊（學員時間偏好、教練時段管理），統一兩端的 UI 設計。

#### 核心設計決策 ⭐

| 設計元素 | 決策 | 理由 |
|---------|------|------|
| **基礎組件** | `ListTile` | Flutter 標準組件，自動處理間距和響應式 |
| **卡片圓角** | `12dp` | 比 16dp 更精緻，視覺上更現代 |
| **卡片間距** | `12dp` | 標準間距，視覺密度適中 |
| **圖標樣式** | `CircleAvatar` | 統一使用圓形背景，視覺一致性 |
| **圖標透明度** | `0.2` | ListTile 默認值 |
| **文字樣式** | ListTile 默認 | 不自訂 fontWeight 或 fontSize |
| **trailing 樣式** | 刪除按鈕或箭頭 | 統一交互模式 |

#### 完整實作範例

```dart
import 'package:flutter/material.dart';

/// 統一的時段卡片組件
/// 
/// 用於學員時間偏好和教練時段管理
class UnifiedSlotCard extends StatelessWidget {
  final String timeRange;
  final IconData icon;
  final Color iconColor;
  final Color? iconBackgroundColor;
  final String? subtitle;
  final String? additionalInfo;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showChevron;

  const UnifiedSlotCard({
    super.key,
    required this.timeRange,
    required this.icon,
    required this.iconColor,
    this.iconBackgroundColor,
    this.subtitle,
    this.additionalInfo,
    this.onTap,
    this.onDelete,
    this.showChevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconBackgroundColor ?? iconColor.withOpacity(0.2),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(timeRange), // 使用 ListTile 默認樣式
        subtitle: (additionalInfo != null || subtitle != null)
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (additionalInfo != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      additionalInfo!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              )
            : null,
        trailing: showChevron
            ? const Icon(Icons.chevron_right)
            : (onDelete != null
                ? IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: '刪除時段',
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}
```

#### 使用範例

**學員時間偏好（顯示刪除按鈕）**：
```dart
UnifiedSlotCard(
  timeRange: '09:00 - 10:00',
  icon: Icons.star,
  iconColor: Colors.amber,
  subtitle: '這段時間精神最好',
  onTap: () => _editSlot(slot),
  onDelete: () => _deleteSlot(slot.id),
)
```

**教練時段管理（行事曆底部，顯示刪除按鈕）**：
```dart
UnifiedSlotCard(
  timeRange: '09:00 - 10:00',
  icon: slot.isRecurring ? Icons.repeat : Icons.event,
  iconColor: slot.isRecurring ? Colors.blue : Colors.green,
  additionalInfo: slot.getRecurrenceDescription(),
  subtitle: slot.notes,
  onTap: () => _showSlotDetails(slot),
  onDelete: () => _deleteSlot(slot.id),
)
```

**導航場景（顯示箭頭）**：
```dart
UnifiedSlotCard(
  timeRange: '09:00 - 10:00',
  icon: Icons.event,
  iconColor: Colors.green,
  onTap: () => Navigator.push(...),
  showChevron: true, // 顯示箭頭而非刪除按鈕
)
```

#### ❌ 常見錯誤

**錯誤 1：自訂文字樣式**
```dart
// ❌ 不要自訂 title 的樣式
title: Text(
  timeRange,
  style: theme.textTheme.titleMedium?.copyWith(
    fontWeight: FontWeight.w600, // 會破壞統一性
  ),
)

// ✅ 使用 ListTile 默認樣式
title: Text(timeRange)
```

**錯誤 2：使用手動 Row/Column 佈局**
```dart
// ❌ 不要手動構建佈局
child: Padding(
  padding: EdgeInsets.all(16),
  child: Row(
    children: [
      CircleAvatar(...),
      SizedBox(width: 16),
      Expanded(child: Column(...)),
    ],
  ),
)

// ✅ 使用 ListTile
child: ListTile(
  leading: CircleAvatar(...),
  title: Text(...),
  subtitle: ...,
)
```

**錯誤 3：不一致的圓角**
```dart
// ❌ 使用 16dp 圓角
borderRadius: BorderRadius.circular(16)

// ✅ 統一使用 12dp
borderRadius: BorderRadius.circular(12)
```

#### 設計檢查清單

使用此組件前，請確認：
- [ ] 使用 `ListTile` 作為基礎組件
- [ ] 圓角統一為 `12dp`
- [ ] 不自訂 `title` 的文字樣式
- [ ] 圖標使用 `CircleAvatar` + `0.2` 透明度
- [ ] `trailing` 只有刪除按鈕或箭頭兩種
- [ ] 卡片間距為 `12dp`

---

## 7. 互動設計與微動畫

> 動態效果是區分「陽春」與「專業」的關鍵

### 7.1 轉場動畫（Transitions）

#### Hero Animation

**應用場景**：動作庫 → 動作詳情頁

```dart
// 列表項目
Hero(
  tag: 'exercise_${exercise.id}',
  child: CircleAvatar(child: Text(exercise.name[0])),
)

// 詳情頁
Hero(
  tag: 'exercise_${exercise.id}',
  child: Image.network(exercise.imageUrl),
)
```

#### Page Transitions

推薦使用：
- **iOS 風格**：`CupertinoPageTransitionsBuilder`（滑動返回）
- **Android 10+ 風格**：`ZoomPageTransitionsBuilder`

```dart
theme: ThemeData(
  pageTransitionsTheme: PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    },
  ),
)
```

### 7.2 觸覺回饋（Haptics）

> 讓使用者「感受」到操作

| 操作 | 觸覺類型 | 實作代碼 |
|------|---------|---------|
| 完成組數 | 輕度撞擊 | `HapticFeedback.lightImpact()` |
| 計時結束 | 連續震動 | `HapticFeedback.vibrate()` |
| 滑動刪除 | 選擇點擊 | `HapticFeedback.selectionClick()` |
| 勾選 Checkbox | 中度撞擊 | `HapticFeedback.mediumImpact()` |

**範例實作**：

```dart
Checkbox(
  value: isCompleted,
  onChanged: (bool? value) {
    HapticFeedback.mediumImpact(); // 觸覺回饋
    setState(() {
      isCompleted = value ?? false;
    });
  },
)
```

### 7.3 輸入優化

#### 1. 自動聚焦（Autofocus）

```dart
TextFormField(
  autofocus: true, // 自動聚焦第一個輸入框
  focusNode: _weightFocusNode,
)
```

#### 2. 鍵盤行動（Keyboard Actions）

```dart
TextFormField(
  textInputAction: TextInputAction.next, // 顯示「Next」
  onFieldSubmitted: (_) {
    FocusScope.of(context).requestFocus(_repsFocusNode); // 跳到下一個
  },
)

TextFormField(
  focusNode: _repsFocusNode,
  textInputAction: TextInputAction.done, // 顯示「Done」
  onFieldSubmitted: (_) {
    FocusScope.of(context).unfocus(); // 收起鍵盤
  },
)
```

#### 3. 數字鍵盤設定

```dart
TextFormField(
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  inputFormatters: [
    FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
  ],
)
```

---

## 8. 無障礙設計（Accessibility）

> 專業的 UI 必須考慮所有使用者

### 8.1 對比度檢查（Contrast Ratio）

#### WCAG 標準
- **AA 級別**：對比度至少 **4.5:1**（常規文字）
- **AAA 級別**：對比度至少 **7:1**（更高標準）

#### 檢查工具
- [WebAIM Contrast Checker](https://webaim.org/resources/contrastchecker/)
- Flutter DevTools（Accessibility Inspector）

#### StrengthWise 檢查清單

| 文字類型 | 淺色模式 | 深色模式 | 對比度 |
|---------|---------|---------|--------|
| 主要文字 | `#0F172A` on `#FFFFFF` | `#F8FAFC` on `#0F172A` | ✅ 14:1 |
| 次要文字 | `#64748B` on `#FFFFFF` | `#CBD5E1` on `#0F172A` | ✅ 5.2:1 |
| 按鈕文字 | `#FFFFFF` on `#2563EB` | `#0F172A` on `#60A5FA` | ✅ 4.8:1 |

**⚠️ 避免使用過淺的灰色**（如 `#E0E0E0` on white）

### 8.2 動態字級（Dynamic Type）

#### 支援系統字體縮放

```dart
Text(
  '運動名稱',
  style: TextStyle(fontSize: 18),
  // ✅ 自動適應系統字體大小設定
)
```

#### 測試不同字體縮放

在 Flutter 中測試：
```dart
MediaQuery(
  data: MediaQuery.of(context).copyWith(textScaleFactor: 1.5),
  child: YourWidget(),
)
```

#### 確保佈局不崩壞
- 使用 `Flexible` / `Expanded`
- 文字應自動換行（避免 `overflow: TextOverflow.clip`）

### 8.3 語意化標籤（Semantic Labels）

```dart
Semantics(
  label: '完成第一組',
  child: Checkbox(
    value: isCompleted,
    onChanged: (value) { },
  ),
)
```

---

## 9. 執行路徑圖

### 階段一：基礎建設（Week 1）⚙️

**目標**：建立設計系統基礎

- [ ] **主題系統**
  - [ ] 創建 `lib/themes/app_theme.dart`
  - [ ] 定義淺色/深色配色方案
  - [ ] 配置 Material 3 主題
- [ ] **字體整合**
  - [ ] 引入 Google Fonts 套件
  - [ ] 整合 Inter + JetBrains Mono
  - [ ] 定義字級系統
- [ ] **圖標系統**
  - [ ] 引入 Hugeicons 套件
  - [ ] 建立圖標清單文檔

**交付物**：可切換深淺模式的空白 App

---

### 階段二：核心重構（Week 2）🎯

**目標**：重寫 WorkoutLogger 視圖

- [ ] **卡片式佈局**
  - [ ] 將 ListView 替換為 Card 結構
  - [ ] 實作動作組卡片（Exercise Card）
  - [ ] 實作輸入列（Input Row）
- [ ] **輸入優化**
  - [ ] 自定義 TextFormField 樣式
  - [ ] 實作數字鍵盤
  - [ ] 實作自動聚焦
  - [ ] 實作鍵盤行動（Next/Done）
- [ ] **完成狀態**
  - [ ] 重新設計 Checkbox UI
  - [ ] 加入觸覺回饋
  - [ ] 實作休息計時器觸發

**交付物**：全新的訓練記錄體驗

---

### 階段三：導航與框架（Week 3）🗺️

**目標**：整合全局導航與儀表板

- [ ] **底部導航**
  - [ ] 實作 BottomNavigationBar
  - [ ] 整合圖標系統
  - [ ] 實作頁面切換動畫
- [ ] **儀表板視圖**
  - [ ] 實作 SliverAppBar
  - [ ] 實作摘要卡片
  - [ ] 實作快速開始區域
- [ ] **主題切換**
  - [ ] 實作 ThemeService
  - [ ] 實作 ThemeProvider
  - [ ] 建立設定頁面
  - [ ] 整合 SegmentedButton

**交付物**：完整的 App 框架與導航

---

### 階段四：細節打磨（Week 4）✨

**目標**：提升體驗與品質

- [ ] **微動畫**
  - [ ] 加入 Hero 動畫
  - [ ] 優化頁面轉場
  - [ ] 加入載入動畫
- [ ] **觸覺回饋**
  - [ ] 整合所有關鍵操作點
- [ ] **無障礙優化**
  - [ ] 對比度檢查
  - [ ] 語意化標籤
  - [ ] 動態字級測試
- [ ] **測試與修復**
  - [ ] 溢出錯誤檢查
  - [ ] 不同屏幕尺寸測試
  - [ ] 深淺模式全面測試

**交付物**：市場級品質的 UI/UX

---

## 附錄 A：HTML 原型到 Flutter 實作指南

> 基於提供的 HTML 原型，以下是詳細的 Flutter 轉換指南

### A.1 色彩系統映射

HTML 原型使用 Tailwind CSS，以下是對應的 Flutter 實作：

| Tailwind Class | HTML 顏色 | Flutter 實作 |
|---------------|-----------|-------------|
| `bg-primary-600` | `#0284c7` | `Theme.of(context).colorScheme.primary` |
| `dark:bg-darkbg` | `#0f172a` | `Theme.of(context).colorScheme.background` |
| `dark:bg-darkcard` | `#1e293b` | `Theme.of(context).colorScheme.surface` |
| `text-gray-900 dark:text-white` | - | `Theme.of(context).colorScheme.onSurface` |
| `border-gray-100 dark:border-gray-700/50` | - | `Theme.of(context).colorScheme.outline` |

### A.2 主頁視圖（Home View）實作

#### HTML 原型特色
```html
<!-- 漸變色 CTA 卡片 -->
<div class="bg-gradient-to-r from-primary-600 to-blue-500 rounded-2xl p-6">
  <h2 class="text-2xl font-bold">上肢推力訓練</h2>
  <button class="mt-4 bg-white text-blue-600 px-4 py-2 rounded-lg">開始訓練</button>
</div>
```

#### Flutter 實作

```dart
/// 主頁 CTA 卡片
class HomeCtaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const HomeCtaCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact(); // 觸覺回饋
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標籤
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '今日計畫',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 標題
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            // 副標題
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            // 按鈕
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '開始訓練',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

#### 統計卡片網格

```dart
/// 統計卡片
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color? iconColor;

  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    this.iconColor,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 圖標與標籤
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor ?? colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 數值
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontFamily: 'JetBrains Mono', // 數據字體
              ),
              children: [
                TextSpan(text: value),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 統計卡片網格
class StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.fitness_center,
            label: '總訓練量',
            value: '12,450',
            unit: 'kg',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            icon: Icons.local_fire_department,
            label: '連續週數',
            value: '4',
            unit: '週',
            iconColor: Colors.orange,
          ),
        ),
      ],
    );
  }
}
```

### A.3 訓練視圖（Workout View）實作

#### HTML 原型特色
```html
<!-- 動作卡片中的組數輸入列 -->
<div class="grid grid-cols-10 gap-2 items-center">
  <div class="col-span-2 text-center">1</div>
  <div class="col-span-3">
    <input type="number" value="60" class="w-full bg-gray-50 rounded text-center">
  </div>
  <div class="col-span-3">
    <input type="number" value="10" class="w-full bg-gray-50 rounded text-center">
  </div>
  <div class="col-span-2">
    <button class="w-6 h-6 bg-green-500 rounded"><i data-lucide="check"></i></button>
  </div>
</div>
```

#### Flutter 實作

```dart
/// 訓練組數輸入列
class SetInputRow extends StatefulWidget {
  final int setNumber;
  final double? weight;
  final int? reps;
  final bool isCompleted;
  final Function(double? weight, int? reps) onUpdate;
  final VoidCallback onComplete;

  const SetInputRow({
    required this.setNumber,
    this.weight,
    this.reps,
    this.isCompleted = false,
    required this.onUpdate,
    required this.onComplete,
    Key? key,
  }) : super(key: key);

  @override
  State<SetInputRow> createState() => _SetInputRowState();
}

class _SetInputRowState extends State<SetInputRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.weight?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.reps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = !widget.isCompleted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // 組數顯示（佔 20%）
          SizedBox(
            width: 40,
            child: Center(
              child: Text(
                '${widget.setNumber}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // 重量輸入（佔 30%）
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _weightController,
              enabled: isActive,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isActive
                    ? colorScheme.surface
                    : colorScheme.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: isActive
                      ? BorderSide(color: colorScheme.primary)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (value) {
                widget.onUpdate(
                  double.tryParse(value),
                  int.tryParse(_repsController.text),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // 次數輸入（佔 30%）
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: _repsController,
              enabled: isActive,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'JetBrains Mono',
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isActive
                    ? colorScheme.surface
                    : colorScheme.surface.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: isActive
                      ? BorderSide(color: colorScheme.primary)
                      : BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: '-',
              ),
              onChanged: (value) {
                widget.onUpdate(
                  double.tryParse(_weightController.text),
                  int.tryParse(value),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          // 完成按鈕（佔 20%）
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.check_circle,
                color: widget.isCompleted
                    ? Colors.green
                    : colorScheme.onSurface.withOpacity(0.3),
                size: 24,
              ),
              onPressed: widget.isCompleted
                  ? null
                  : () {
                      HapticFeedback.mediumImpact();
                      widget.onComplete();
                    },
            ),
          ),
        ],
      ),
    );
  }
}
```

#### 動作卡片

```dart
/// 訓練動作卡片
class ExerciseCard extends StatelessWidget {
  final String exerciseName;
  final List<SetData> sets;
  final VoidCallback onAddSet;
  final VoidCallback onMenu;

  const ExerciseCard({
    required this.exerciseName,
    required this.sets,
    required this.onAddSet,
    required this.onMenu,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 標題列
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exerciseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: onMenu,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 表頭
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                const SizedBox(width: 40),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'kg',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.4),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Text(
                    'REPS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.4),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const SizedBox(width: 32),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // 組數列表
          ...sets.asMap().entries.map((entry) {
            return SetInputRow(
              setNumber: entry.key + 1,
              weight: entry.value.weight,
              reps: entry.value.reps,
              isCompleted: entry.value.isCompleted,
              onUpdate: (weight, reps) {
                // 更新邏輯
              },
              onComplete: () {
                // 完成邏輯
              },
            );
          }).toList(),
          const SizedBox(height: 16),
          // 新增組數按鈕
          TextButton(
            onPressed: onAddSet,
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
              backgroundColor: colorScheme.primary.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              '+ 新增組數',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 組數數據模型
class SetData {
  final double? weight;
  final int? reps;
  final bool isCompleted;

  SetData({
    this.weight,
    this.reps,
    this.isCompleted = false,
  });
}
```

### A.4 歷史視圖（History View）實作

#### 日曆條帶

```dart
/// 日曆條帶
class CalendarStrip extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const CalendarStrip({
    required this.selectedDate,
    required this.onDateSelected,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final dates = List.generate(
      7,
      (index) => now.subtract(Duration(days: 3 - index)),
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dates.map((date) {
          final isSelected = date.day == selectedDate.day;
          final isToday = date.day == now.day;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onDateSelected(date);
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  Text(
                    _getWeekdayName(date.weekday),
                    style: TextStyle(
                      fontSize: 12,
                      color: isToday
                          ? colorScheme.primary
                          : colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const names = ['週一', '週二', '週三', '週四', '週五', '週六', '週日'];
    return names[weekday - 1];
  }
}
```

#### 時間軸歷史卡片

```dart
/// 時間軸項目
class TimelineHistoryCard extends StatelessWidget {
  final String title;
  final DateTime dateTime;
  final String duration;
  final String totalWeight;
  final String? prExercise;
  final bool isCompleted;

  const TimelineHistoryCard({
    required this.title,
    required this.dateTime,
    required this.duration,
    required this.totalWeight,
    this.prExercise,
    this.isCompleted = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 時間軸線與圓點
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isCompleted ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.background,
                    width: 2,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: colorScheme.outline.withOpacity(0.3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // 內容
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(dateTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            duration,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.fitness_center, size: 14, color: colorScheme.onSurface.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          Text(
                            totalWeight,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (prExercise != null) ...[
                            const SizedBox(width: 16),
                            const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              'PR: $prExercise',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}月 ${dt.day}日 • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
```

### A.5 底部導航欄

```dart
/// 底部導航欄
class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigation({
    required this.currentIndex,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home,
                label: '主頁',
                index: 0,
              ),
              // 中間的 FAB
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onTap(1);
                },
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              _buildNavItem(
                context,
                icon: Icons.calendar_today,
                label: '紀錄',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap(index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.4),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }
}
```

### A.6 關鍵設計模式總結

| 設計元素 | HTML 實作 | Flutter 對應 |
|---------|-----------|-------------|
| **漸變背景** | `bg-gradient-to-r from-primary-600 to-blue-500` | `LinearGradient` |
| **圓角卡片** | `rounded-2xl` (16px) | `BorderRadius.circular(16)` |
| **陰影效果** | `shadow-lg` | `BoxShadow` |
| **深色模式** | `dark:bg-darkbg` | `Theme.of(context).brightness` |
| **觸控目標** | `w-6 h-6` (24px) → 需增大 | 最小 48dp |
| **間距系統** | Tailwind spacing (4, 8, 16...) | 8 點網格 |
| **等寬字體** | 未使用（建議加入） | `fontFamily: 'JetBrains Mono'` |
| **觸覺回饋** | 未實作 | `HapticFeedback.mediumImpact()` |

### A.7 待優化項目

基於 HTML 原型，以下是 Flutter 實作時需要優化的地方：

1. **觸控目標尺寸**
   - HTML 的勾選按鈕只有 24×24px
   - Flutter 應改為 48×48dp（含 padding）

2. **等寬字體**
   - HTML 未使用等寬字體顯示數字
   - Flutter 應使用 JetBrains Mono 防止數字跳動

3. **觸覺回饋**
   - HTML 無法實現
   - Flutter 應在所有關鍵操作點加入 HapticFeedback

4. **無障礙標籤**
   - HTML 缺少 ARIA 標籤
   - Flutter 應使用 Semantics Widget

5. **動畫效果**
   - HTML 只有基礎 transition
   - Flutter 可加入 Hero 動畫、頁面轉場

---

## 附錄 B：設計檢查清單

### 每次提交前檢查

- [ ] 所有間距都是 8 的倍數
- [ ] 觸控目標最小 48dp
- [ ] 深淺模式都測試過
- [ ] 無溢出錯誤（黃黑條紋）
- [ ] 對比度符合 WCAG AA
- [ ] 關鍵操作有觸覺回饋
- [ ] 文字可閱讀（字級、顏色）
- [ ] 導航邏輯正確
- [ ] 加入繁體中文註解
- [ ] 數字欄位使用等寬字體
- [ ] 漸變色正確映射主題色彩

---

## 附錄 C：參考資源

### 設計系統
- [Material Design 3](https://m3.material.io/)
- [8-Point Grid System](https://spec.fm/specifics/8-pt-grid)
- [Color Accessibility](https://webaim.org/articles/contrast/)

### Flutter 資源
- [Flutter Theming Guide](https://docs.flutter.dev/cookbook/design/themes)
- [Material 3 for Flutter](https://docs.flutter.dev/ui/design/material)
- [Google Fonts Package](https://pub.dev/packages/google_fonts)

### 設計靈感
- [Dribbble - Fitness App](https://dribbble.com/tags/fitness-app)
- [Hevy App](https://www.hevyapp.com/)
- [Strong App](https://www.strong.app/)

---

## 更新日誌

| 日期 | 版本 | 變更內容 |
|------|------|---------|
| 2024-12-25 | 1.0 | 初版發布：完整的 UI/UX 設計規範 |

---

**維護者**：StrengthWise 開發團隊  
**聯絡方式**：詳見 `README.md`  
**授權**：內部專案文檔

---

**相關文檔**：
- [AGENTS.md](../AGENTS.md) - AI 開發指南
- [PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) - 專案架構
- [DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md) - 開發狀態


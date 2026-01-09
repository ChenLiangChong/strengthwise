# StrengthWise 企業級響應式架構設計白皮書

> 跨平台適配與工程實踐

**建立日期**：2026-01-05  
**狀態**：🚧 開發中（P2 已完成）  
**優先級**：🔥 高（Phase 0）

---

## 執行摘要

隨著 StrengthWise 專案從單機版應用轉型為涵蓋教練端與學員端的雙端雙向互動平台，其技術架構面臨著前所未有的挑戰。在當前的數位生態系中，使用者不再受限於單一設備，而是在手機、平板、桌面電腦甚至折疊式裝置之間流暢切換。為了支撐這種無縫的體驗，單純的 UI 縮放已不足以應對，必須構建一套「**企業級的響應式架構 (Enterprise-Grade Responsive Architecture)**」。

本報告旨在為 StrengthWise 提供一份詳盡的技術藍圖，深入探討如何利用 Flutter 的跨平台特性，結合 Material 3 設計規範與 Clean Architecture 架構原則，實現一套代碼庫對多種硬體型態的完美適配。

本報告將響應式設計提升至架構層面，論證了真正的適配不僅是視覺元素的重排，更涉及路由系統的狀態管理、輸入模態的深層整合以及自動化測試策略的革新。

透過對核心斷點系統、自適應導航架構、內容佈局模式、多模態輸入適配及視覺回歸測試的全面剖析，我們為開發團隊提供了一套可落地、可維護且具備高度擴展性的實施標準。

---

## 1. 核心斷點系統 (Breakpoint System) 與適配邏輯

在構建企業級響應式應用時，斷點系統（Breakpoint System）是決定使用者介面如何隨環境變化的基石。

### 1.1 從像素對齊轉向視窗尺寸等級

企業級應用不應再關注具體的物理設備型號，而應關注應用程式可用的視窗空間。

基於 Material 3 設計規範，並針對 StrengthWise 的實際使用情境（舊款手機、各類平板、桌面），我們採用**7 級精細化斷點系統**：

| 視窗尺寸等級 | 代碼名稱 | 斷點範圍 | 縮放係數 | 對應設備 | 佈局特徵 |
|-------------|---------|---------|---------|---------|---------|
| **Compact-S** | `mobileSmall` | < 360dp | 0.88 | iPhone SE、舊款 Android | 緊湊單欄：縮小字體間距，防止溢出 |
| **Compact** | `mobile` | 360-599dp | 1.0 | 標準手機（基準） | 單欄佈局：底部導航，全螢幕模態 |
| **Compact-L** | `mobileLarge` | 600-719dp | 1.05 | 大型手機、摺疊機內屏 | 過渡佈局：可嘗試簡單分欄 |
| **Medium-S** | `tabletSmall` | 720-839dp | 1.1 | iPad Mini、小型平板 | 雙欄開始：Navigation Rail |
| **Medium** | `tablet` | 840-1023dp | 1.15 | iPad Air、標準平板 | 雙欄佈局：Master-Detail |
| **Expanded** | `tabletLarge` | 1024-1279dp | 1.15 | iPad Pro 12.9"、小筆電 | 多欄佈局：常駐 Drawer |
| **Large** | `desktop` | ≥ 1280dp | 1.2 | 桌面顯示器 | 寬鬆佈局：限制最大寬度，輔助面板 |

**設計決策說明**：

1. **為何新增 `mobileSmall`？**  
   許多學員仍使用舊款手機（如 Realme 7 5G 在某些顯示設定下），需要更細緻的適配以防止 UI 溢出。

2. **為何將 Medium 細分？**  
   600-839dp 的範圍跨度太大，720dp 的 iPad Mini 與 600dp 的大型手機在佈局上應有區別。

3. **為何 desktop 起始於 1280dp？**  
   1280dp 是主流筆電（13-14 吋）的標準寬度，1600dp 的閾值過於保守。

### 1.2 斷點系統的架構實作：單一真理來源

為了貫徹這一標準，StrengthWise 專案必須在架構層面封裝斷點邏輯，**嚴禁在個別 Widget 中直接使用 `MediaQuery.of(context).size.width` 進行原始數值的判斷**。

建議採用**響應式上下文擴展 (Responsive Context Extensions)** 模式：

```dart
// ✅ 正確：使用封裝的擴展
if (context.isMobile) { ... }
final columns = context.layoutColumns;

// ❌ 禁止：直接查詢
if (MediaQuery.of(context).size.width < 600) { ... }
```

此外，對於更細粒度的佈局控制，應引入 `LayoutBuilder`。與 `MediaQuery` 獲取螢幕整體尺寸不同，`LayoutBuilder` 提供的是父容器給予的約束（Constraints）。這種「**組件級響應式**」是企業級架構與普通響應式設計的分水嶺。

### 1.3 摺疊裝置與雙螢幕的適配策略

StrengthWise 作為一個前瞻性的專案，應考慮引入對**摺疊感知 (Foldable Awareness)** 的支援。

利用 `flutter_adaptive_scaffold` 或 Microsoft 的 `dual_screen` 套件，架構可以檢測 `DisplayFeature`。當應用跨越兩個螢幕顯示時，系統應自動將佈局切換為**雙窗格模式 (Two-Pane Mode)**。

### 1.4 動態重流與過渡動畫

在桌面端，使用者調整視窗大小是連續的行為。StrengthWise 應採用**平滑的動態重流 (Dynamic Reflow)** 策略。

當視窗從 Medium 過渡到 Expanded 時，網格佈局的欄數變化應伴隨著元素的平滑位移與縮放，而非瞬間替換。這需要結合 `AnimatedContainer`、`AnimatedSwitcher` 或 `Hero` 動畫來維持視覺連續性。

---

## 2. 導航架構的自適應切換

導航系統是應用程式的骨架，決定了使用者如何在功能間穿梭。

### 2.1 導航模式的適應性矩陣

StrengthWise 需根據設備尺寸自動切換三種標準導航模式：

#### 2.1.1 底部導航欄 (Bottom Navigation Bar)

- **適用場景**：`mobileSmall`、`mobile`、`mobileLarge` (< 720dp)
- **設計邏輯**：手機操作以拇指為主，底部是熱區。此模式下僅展示 3-5 個核心功能。
- **空間權衡**：犧牲了部分垂直內容空間，換取操作便捷性。

#### 2.1.2 側邊導航軌 (Navigation Rail)

- **適用場景**：`tabletSmall`、`tablet` (720dp - 1023dp)
- **設計邏輯**：當螢幕變寬但仍受限時，垂直空間變得寶貴。Navigation Rail 位於左側，寬度固定（約 72dp-80dp），通常僅顯示圖標。
- **優勢**：釋放垂直空間給內容流，同時利用平板較寬的邊緣。

#### 2.1.3 標準/常駐側邊欄 (Navigation Drawer)

- **適用場景**：`tabletLarge`、`desktop` (≥ 1024dp)
- **設計邏輯**：在寬螢幕上，左側有足夠空間展示完整的導航結構。
- **行為模式**：應設定為「永久顯示 (Permanent)」，與內容區域並排。

### 2.2 技術實作：基於 Slot 的自適應框架

建議採用 `flutter_adaptive_scaffold` 或自建 `ResponsiveBuilder`。以下是 7 級斷點對應的導航配置：

| 螢幕類型 | 導航模式 | Body | Secondary Body |
|---------|---------|------|----------------|
| `mobileSmall` / `mobile` / `mobileLarge` | BottomNavigationBar | 佔據剩餘空間 | 透過 Push 進入 |
| `tabletSmall` / `tablet` | NavigationRail | 與 Rail 並排 | 視情況顯示 |
| `tabletLarge` / `desktop` | NavigationDrawer (常駐) | 與 Drawer 並排 | 顯示詳情頁或輔助面板 |

### 2.3 關鍵架構挑戰：路由狀態保存 (State Preservation)

這是大多數響應式應用失敗的地方。

**解決方案：結合 GoRouter 的 StatefulShellRoute**

- **多 Navigator 並行**：每個導航分支都擁有自己獨立的 Navigator 和 GlobalKey。
- **IndexedStack 機制**：非活動狀態的 Widget 樹並沒有被銷毀，而是被「隱藏」了（Offstage）。因此，所有的 State 物件都完好無損地保留在記憶體中。
- **無縫切換**：當 AdaptiveScaffold 觸發導航模式切換時，它操作的是外層的殼（Shell），而內部的內容頁面保持不變。

---

## 3. 內容佈局模式 (Content Layout Patterns)

內容區域是使用者完成任務的核心場所。

### 3.1 Master-Detail (List-Detail) 模式的深度解析

對於「學員管理」或「預約列表」功能：

**Compact (手機) 行為**：
- 採用標準的堆疊式導航
- 使用者點擊列表中的項目，應用透過 `Navigator.push` 將詳情頁推入堆疊頂層

**Expanded (桌面/平板) 行為**：
- 採用並排顯示（Side-by-Side）
- 左側列表固定寬度（或佔 30-40%），右側詳情頁佔據剩餘空間

### 3.2 網格重流 (Grid Reflow) 與 Masonry 佈局

**最佳實踐：基於最大寬度的重流演算法**

StrengthWise 應摒棄固定的 `crossAxisCount`，轉而使用 `SliverGridDelegateWithMaxCrossAxisExtent`：

- 手機 (360dp)：1 欄
- 平板 (800dp)：2 欄
- 桌面 (1440dp)：3 或 4 欄

### 3.3 輔助面板 (Supporting Panel) 與最大寬度限制

在 Extra-Large (1600dp+) 的超寬螢幕上：

- **居中與限寬**：內容區域應設定 `Constraints(maxWidth: 840dp)` 並居中顯示
- **利用邊距**：多餘的空間不應只是留白，而應轉化為輔助面板
- **對話框策略**：在手機上呈現為全螢幕或 BottomSheet；在桌面上則回歸標準的模態對話框

---

## 4. 輸入方式的適應 (Input Modality Adaptation)

StrengthWise 的雙端特性意味著它必須同時服務於「觸控優先」的手機/平板用戶，以及「滑鼠鍵盤優先」的桌面端教練。

### 4.1 觸控與滑鼠的互動模型差異

| 特性 | 觸控 (Touch) | 滑鼠/觸控板 (Mouse) |
|-----|-------------|-------------------|
| 點擊目標 | 需大於 48x48dp 以容錯 | 可精確至 20x20dp |
| 狀態回饋 | 按下 (Pressed) 狀態為主 | 依賴懸停 (Hover) 預覽互動性 |
| 滾動行為 | 慣性拖曳 (Drag) | 滾輪 (Scroll Wheel) |
| 輔助操作 | 長按 (Long Press) 或滑動 | 右鍵 (Right-click) 或快捷鍵 |

**實作策略**：

- **Visual Density 調整**：在桌面端設為 `VisualDensity.compact`，在移動端設為 `VisualDensity.standard`
- **全面懸停支援**：所有可互動元素必須在桌面端支援懸停狀態變化

### 4.2 桌面級右鍵選單 (Context Menus)

- **Web/Desktop**：使用 `ContextMenuRegion` 彈出自定義選單
- **Mobile**：保留長按或滑動手勢

### 4.3 鍵盤優先與焦點管理

**快捷鍵架構 (Shortcuts & Actions)**：

```dart
// 建立語義化的 Intent 與 Action
class SaveIntent extends Intent {}

// 桌面端綁定 Ctrl+S
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): SaveIntent(),
  },
  child: Actions(
    actions: {
      SaveIntent: CallbackAction<SaveIntent>(onInvoke: (_) => save()),
    },
    child: content,
  ),
)
```

**焦點遍歷**：使用 `FocusTraversalGroup` 將表單區域分組，確保 Tab 鍵能依照邏輯順序跳轉。

---

## 5. 自動化測試策略 (Automated Testing Strategy)

響應式架構的複雜性在於排列組合的爆炸式增長。

### 5.1 黃金檔測試 (Golden Tests) 的革新

**工具選型：Alchemist**

Alchemist 的優勢：它提供了專用的 CI 模式，能自動將所有文字替換為標準的色塊，使得測試專注於佈局結構與尺寸正確性。

### 5.2 多尺寸場景的自動化矩陣

```dart
goldenTest(
  'Dashboard Responsiveness Matrix',
  fileName: 'dashboard_matrix',
  builder: () => GoldenTestGroup(
    children: [
      GoldenTestScenario(
        name: 'Mobile',
        constraints: BoxConstraints.tight(Size(375, 812)),
        child: DashboardPage(),
      ),
      GoldenTestScenario(
        name: 'Tablet',
        constraints: BoxConstraints.tight(Size(834, 1194)),
        child: DashboardPage(),
      ),
      GoldenTestScenario(
        name: 'Desktop',
        constraints: BoxConstraints.tight(Size(1440, 900)),
        child: DashboardPage(),
      ),
    ],
  ),
);
```

### 5.3 CI/CD 流水線整合

- **環境一致性**：使用 Docker 容器鎖定 Flutter 版本
- **分層測試**：`flutter test` 執行單元測試；`flutter test --tags=golden` 執行視覺測試
- **失敗處理**：CI 系統應自動生成並上傳「差異圖（Diff Image）」

---

## 6. 架構總結與 Clean Architecture 整合

響應式邏輯應嚴格限制在 **Presentation Layer（表現層）**，絕不應洩漏至 Domain 或 Data Layer。

### Clean Architecture 分層建議

| Layer | 責任 | 響應式感知 |
|-------|-----|-----------|
| **Presentation Layer** | Widgets、Pages、State Management | ✅ 知道螢幕尺寸 |
| **Domain Layer** | UseCases、Entities | ❌ 完全不感知 |
| **Data Layer** | Repository、Data Sources | ❌ 完全不感知 |

**重要原則**：Bloc/Cubit 不應知道當前是 Mobile 還是 Desktop。它只負責發送 `DataLoaded` 狀態，由 UI 層決定是用 List 展示還是用 Grid 展示。

---

## 結論

StrengthWise 的企業級響應式架構並非單一技術的應用，而是對斷點系統、導航模式、內容策略、輸入互動與測試體系的全面整合。

透過實施本報告規劃的架構，StrengthWise 將能以單一套 Flutter 代碼庫，優雅地跨越設備鴻溝，為教練提供高效的桌面級生產力工具，同時為學員提供便捷的移動端體驗，達成真正的「**一次編寫，處處運行 (Write Once, Run Anywhere)**」且不犧牲使用者體驗的戰略目標。

---

## 附錄：與現有規範的整合點

### 與 `300-ui-ux-design.mdc` 的對應

| 白皮書建議 | 現有規範 | 狀態 |
|-----------|---------|------|
| 48dp 最小觸控目標 | ✅ 已有 `minTouchTarget = 48.0` | ✅ 一致 |
| 8 點網格系統 | ✅ 已有完整間距常量 | ✅ 一致 |
| 使用 Theme 顏色 | ✅ 禁止硬編碼顏色 | ✅ 一致 |
| 7 級斷點系統 | ✅ `lib/utils/responsive/` | ✅ 已實作 |

### 已實作的響應式框架

| 功能 | 檔案 | 狀態 |
|------|------|------|
| 斷點定義 | `responsive_breakpoints.dart` | ✅ 完成 |
| Context Extension | `responsive_extensions.dart` | ✅ 完成 |
| 響應式文字 | `responsive_text_styles.dart` | ✅ 完成 |
| 響應式建構器 | `responsive_builder.dart` | ✅ 完成 |
| 統一導出 | `responsive.dart` | ✅ 完成 |

### 已更新的開發規範

- [x] 禁止直接使用 `MediaQuery.of(context).size.width`
- [x] 響應式組件必須使用 `context.responsive` 擴展
- [x] 大螢幕佈局需限制最大內容寬度（`ResponsiveContainer`）
- [x] 間距縮放後對齊到 4dp 網格

### 待實作項目

| 項目 | 優先級 | 說明 | 狀態 |
|------|-------|------|------|
| 自適應導航 | 中 | Bottom → Rail（160dp 帶標籤） | ✅ 2026-01-05 |
| 響應式字體比例 | 中 | 平板/桌面 scaleFactor 1.0 | ✅ 2026-01-05 |
| Master-Detail | 中 | 大螢幕分欄佈局 | ⏳ |
| 輸入模式適配 | 低 | 懸停、右鍵、快捷鍵 | 🔮 |
| Golden Tests | 低 | 多尺寸視覺測試 | 🔮 |
| 摺疊裝置支援 | 低 | DisplayFeature 檢測 | 🔮 |


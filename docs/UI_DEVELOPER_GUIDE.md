# StrengthWise - UI 開發指南

> 快速查表與代碼參考

**版本**：2.2
**最後更新**：2026年1月19日

---

## 1. 色彩快查表

### 1.1 主要色彩

| 用途 | 淺色模式 | 深色模式 | Flutter 變數 |
|------|---------|---------|-------------|
| **Primary** | `#0EA5E9` | `#38BDF8` | `colorScheme.primary` |
| **On Primary** | `#FFFFFF` | `#0F172A` | `colorScheme.onPrimary` |
| **Secondary** | `#0D9488` | `#2DD4BF` | `colorScheme.secondary` |
| **Background** | `#F1F5F9` | `#0F172A` | `colorScheme.background` |
| **Surface** | `#FFFFFF` | `#1E293B` | `colorScheme.surface` |
| **On Surface** | `#0F172A` | `#FFFFFF` | `colorScheme.onSurface` |
| **Outline** | `#CBD5E1` | `#334155` | `colorScheme.outline` |

### 1.2 語意色彩

| 用途 | 淺色模式 | 深色模式 |
|------|---------|---------|
| **Success** | `#10B981` | `#34D399` |
| **Error** | `#EF4444` | `#EF4444` |
| **Warning** | `#F59E0B` | `#FBBF24` |

---

## 2. 響應式斷點系統 ⭐ v2.0 新增

### 2.1 視窗尺寸等級

| 等級 | 寬度範圍 | 縮放係數 | 典型設備 |
|------|---------|---------|---------|
| **mobileSmall** | < 360dp | 0.88 | iPhone SE、舊款 Android |
| **mobile** | 360-599dp | 1.0 | 標準手機（基準） |
| **mobileLarge** | 600-719dp | 1.05 | 大型手機、摺疊機 |
| **tabletSmall** | 720-839dp | 1.0 | 小型平板 |
| **tablet** | 840-1023dp | 1.0 | 標準平板 |
| **tabletLarge** | 1024-1279dp | 1.0 | 大型平板、小筆電 |
| **desktop** | ≥ 1280dp | 1.0 | 桌面顯示器 |

> ⚠️ **2026-01-05 更新**：平板/桌面 scaleFactor 從 1.1-1.2 改為 1.0，以與 NavigationRail (72-160dp) 比例協調。

### 2.2 使用方式

```dart
import 'package:strengthwise/utils/responsive/responsive.dart';

// 1. 快速判斷螢幕類型
if (context.isMobile) { ... }
if (context.isTablet) { ... }
if (context.isDesktop) { ... }

// 2. 獲取螢幕類型
final type = context.screenType; // ScreenType.mobile

// 3. 獲取縮放係數
final scale = context.scaleFactor; // 0.88 ~ 1.2
```

### 2.3 響應式佈局建構器

```dart
// 根據螢幕尺寸顯示不同佈局
ResponsiveBuilder(
  mobile: (context, constraints) => MobileLayout(),
  tablet: (context, constraints) => TabletLayout(),
  desktop: (context, constraints) => DesktopLayout(),
)

// 響應式 Grid（自動計算欄數）
ResponsiveGrid(
  mobileColumns: 1,
  tabletColumns: 2,
  desktopColumns: 3,
  children: items.map((item) => ItemCard(item)).toList(),
)

// 條件顯示
ResponsiveVisibility(
  hiddenWhen: [ScreenType.mobileSmall, ScreenType.mobile],
  child: SidePanel(),
)
```

### 2.4 自適應導航 ⭐ v2.0 新增

| 螢幕類型 | 導航模式 | 寬度 | 特徵 |
|---------|---------|------|------|
| 手機 (<720dp) | `BottomNavigationBar` | N/A | 底部 5 個圖標 |
| 平板 (720-1023dp) | `NavigationRail` | 72dp | 僅圖標，hover tooltip |
| 桌面 (≥1024dp) | `NavigationRail(extended)` | 160dp | 圖標 + 標籤 |

```dart
// 使用 AdaptiveNavigationScaffold 自動切換
AdaptiveNavigationScaffold(
  selectedIndex: _selectedIndex,
  onDestinationSelected: (index) => setState(() => _selectedIndex = index),
  destinations: [
    NavigationItem(icon: Icons.home_outlined, selectedIcon: Icons.home, label: '首頁'),
    // ...
  ],
  body: _pages[_selectedIndex],
)
```

### 2.5 Master-Detail 分欄佈局 ⭐ P3 新增

| 螢幕類型 | 行為 | Master 寬度 |
|---------|------|------------|
| 手機 (<720dp) | Push 到詳情頁 | N/A |
| 平板/桌面 (≥720dp) | 左右分欄 | 350-380dp |

```dart
// 使用 MasterDetailLayout 自動切換
MasterDetailLayout(
  master: ListView(...),  // 左側列表
  detail: selectedItem != null
      ? DetailContent(item: selectedItem)  // 右側詳情
      : null,  // 顯示空狀態
  masterWidth: 350,  // 可選，預設 350
)
```

**已實作頁面**：
- `appointments_list_page.dart` → `AppointmentDetailsContent`
- `client_management_page.dart` → `ClientDetailContent`

## 3. 字體快查表

### 3.1 字級系統（Material 3）

| 語意角色 | 字體 | 大小 | 字重 | 用途 |
|---------|------|------|------|------|
| Display Large | Inter | 32sp | Bold (700) | 總訓練量、PR 慶祝 |
| Headline Medium | Inter | 24sp | SemiBold (600) | 頁面標題 |
| Title Medium | Inter | 18sp | Medium (500) | 卡片標題 |
| Body Large | Inter | 16sp | Regular (400) | 一般說明 |
| Body Medium | Inter | 14sp | Regular (400) | 次要資訊 |
| Label Large | Manrope | 14sp | Medium (500) | 按鈕文字 |
| **Data Large** | JetBrains Mono | 20sp | Medium (500) | 重量/次數 |
| **Data Medium** | JetBrains Mono | 14sp | Regular (400) | 計時器 |

### 3.2 響應式字體 ⭐ v2.0 新增

```dart
// ✅ 推薦：使用響應式文字樣式
Text(
  '標題',
  style: context.responsive.headlineMedium,
)

// ✅ 推薦：使用 Theme textTheme
Text(
  '標題',
  style: Theme.of(context).textTheme.headlineMedium,
)

// ✅ 數據顯示（響應式）
Text(
  '100.5',
  style: context.responsive.dataLarge,
)

// ❌ 禁止：硬編碼固定字體大小
Text(
  '標題',
  style: TextStyle(fontSize: 24), // 不會適配小螢幕
)
```

### 3.3 響應式字體縮放表

| 基準大小 | 小型手機 (×0.88) | 標準手機 (×1.0) | 平板 (×1.15) |
|---------|-----------------|----------------|--------------|
| 24sp | 21sp | 24sp | 28sp |
| 18sp | 16sp | 18sp | 21sp |
| 16sp | 14sp | 16sp | 18sp |
| 14sp | 12sp | 14sp | 16sp |

---

## 4. 間距快查表（8 點網格）

### 4.1 標準間距

| 規範名稱 | 數值 | AppTheme 常量 | 應用場景 |
|---------|------|--------------|---------|
| Micro | 4dp | `spacingXs` | 極小間距（文字與圖標） |
| Element | 8dp | `spacingSm` | 元素內部間距 |
| Card | 12dp | - | 卡片間距 |
| Container | 16dp | `spacingMd` | 頁面邊距、卡片內距 |
| Section | 24dp | `spacingLg` | 區塊分隔 |
| Large | 32dp | `spacingXl` | 大區塊分隔 |
| Touch Target | 48dp | `minTouchTarget` | 按鈕最小高度 |

### 4.2 響應式間距 ⭐ v2.0 新增

```dart
// ✅ 推薦：使用響應式間距
Padding(
  padding: EdgeInsets.all(context.spacing.md), // 自動縮放
  child: content,
)

// ✅ 推薦：使用預設頁面邊距
Padding(
  padding: context.pagePadding, // 自動適配螢幕
  child: content,
)

// ✅ 推薦：使用預設卡片內距
Card(
  child: Padding(
    padding: context.cardPadding,
    child: content,
  ),
)

// ❌ 禁止：硬編碼間距
Padding(
  padding: EdgeInsets.all(16), // 不會適配小螢幕
)
```

### 4.3 響應式間距對照表

| 間距類型 | 小型手機 | 標準手機 | 平板 | 桌面 |
|---------|---------|---------|------|------|
| `spacing.xs` | 2dp | 4dp | 4dp | 4dp |
| `spacing.sm` | 4dp | 8dp | 8dp | 10dp |
| `spacing.md` | 12dp | 16dp | 18dp | 20dp |
| `spacing.lg` | 16dp | 24dp | 28dp | 32dp |
| `spacing.xl` | 24dp | 32dp | 36dp | 40dp |
| `pagePadding` | 12dp | 16dp | 32dp | 48dp |
| `cardPadding` | 12dp | 16dp | 20dp | 24dp |

---

## 5. 響應式佈局快查表 ⭐ v2.0 新增

### 5.1 Grid 欄數建議

| 螢幕類型 | `gridColumns` | `listColumns` | 用途 |
|---------|--------------|---------------|------|
| mobileSmall | 1 | 1 | 單欄列表 |
| mobile | 1 | 1 | 單欄列表 |
| mobileLarge | 2 | 1 | 可嘗試雙欄 |
| tablet | 3 | 2 | 雙欄列表 |
| desktop | 4 | 3 | 多欄佈局 |

### 5.2 導航模式

| 螢幕類型 | 斷點範圍 | 導航模式 | 說明 |
|---------|---------|---------|------|
| `mobileSmall` / `mobile` / `mobileLarge` | < 720dp | `BottomNavigationBar` | 底部導航，3-5 個項目 |
| `tabletSmall` / `tablet` | 720-1023dp | `NavigationRail` | 側邊導航軌，僅圖標 |
| `tabletLarge` / `desktop` | ≥ 1024dp | `NavigationDrawer` | 常駐側邊欄，圖標+文字 |

### 5.3 內容最大寬度

```dart
// 大螢幕限制內容寬度
ResponsiveContainer(
  maxWidth: 1200, // dp
  child: content,
)

// 或手動限制
ConstrainedBox(
  constraints: BoxConstraints(maxWidth: 840),
  child: content,
)
```

---

## 6. 圓角與陰影

### 6.1 圓角規範

| 元素 | 圓角 | 說明 |
|------|------|------|
| 卡片 | 20dp | 統一使用（v4.0 更新）|
| 按鈕 | 8dp 或 12dp | 取決於尺寸 |
| 輸入框 | 8dp | 標準輸入框 |
| 底部導航 | 0dp | 不使用圓角 |

### 6.2 陰影規範

| 模式 | 策略 | 說明 |
|------|------|------|
| 淺色模式 | `elevation: 0` + 邊框 | 使用邊框區分層次 |
| 深色模式 | `elevation: 0` | 用背景色差區分層次 |

```dart
// 淺色模式卡片
CardTheme(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(color: Color(0xFFE2E8F0)),
  ),
)

// 深色模式卡片
CardTheme(
  elevation: 0,
  color: Color(0xFF1E293B), // 比背景稍亮
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
)
```

---

## 7. 圖標規範

### 7.1 風格

- **描邊寬度**：1.5dp 或 2dp
- **未選中**：Outline（描邊）
- **選中**：Filled（實心）
- **推薦套件**：Hugeicons / Phosphor Icons

### 7.2 常用圖標

| 類別 | 圖標 | 用途 |
|------|------|------|
| 導航 | `home` | 儀表板 |
| | `fitness_center` | 動作庫 |
| | `calendar_today` | 歷史紀錄 |
| | `person` | 個人檔案 |
| 操作 | `add` | 新增 |
| | `delete_outline` | 刪除 |
| | `timer` | 休息計時 |
| 狀態 | `check_circle` | 完成 |
| | `local_fire_department` | 連續紀錄 |

---

## 8. 組件規範

### 8.1 統一卡片（UnifiedSlotCard）

```dart
UnifiedSlotCard(
  timeRange: '09:00 - 10:00',
  icon: Icons.event,
  iconColor: Colors.green,
  subtitle: '備註文字',
  onTap: () => {},
  onDelete: () => {}, // 或 showChevron: true
)
```

**設計規範**：
- 使用 `ListTile` 作為基礎
- 圓角：12dp
- 間距：12dp
- 不自訂 title 文字樣式

### 8.2 輸入框

```dart
TextFormField(
  keyboardType: TextInputType.numberWithOptions(decimal: true),
  textAlign: TextAlign.center,
  style: TextStyle(
    fontFamily: 'JetBrains Mono', // 數據用等寬
    fontWeight: FontWeight.bold,
  ),
  decoration: InputDecoration(
    filled: true,
    fillColor: colorScheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  ),
)
```

### 8.3 擴展 FAB（SpeedDial）⭐ v3.1 新增

Session Mode 使用的圓形散開動畫 FAB：

```dart
SessionSpeedDial(
  onPhotoPressed: () => _handlePhoto(),
  onDrawingPressed: (templateType) => _handleDrawing(templateType),
  onAddExercisePressed: () => _handleAddExercise(),
)
```

**設計規範**：
- 圓形按鈕，散開動畫（`Curves.easeOut` / `easeIn`）
- 主按鈕：56dp，子按鈕：48dp
- 子按鈕顯示在主按鈕上方（不是下方）
- 無灰色背景遮罩
- 繪圖按鈕可再展開四個模板選項
- 按下回饋：`scale: 0.92`

**檔案位置**：`lib/views/pages/session/widgets/session_speed_dial.dart`

### 8.4 照片網格（UploadedPhotoGrid）⭐ v3.1 新增

顯示已上傳照片的可復用網格組件：

```dart
UploadedPhotoGrid(
  photos: visualElements.whereType<PhotoElementModel>().toList(),
  readOnly: false,
  onRemove: (photo) => _handleRemovePhoto(photo),
)
```

**設計規範**：
- 自動處理 Supabase Storage signed URL
- 支援 loading / error 狀態
- 可選 `onRemove` 回調（唯讀模式不顯示刪除按鈕）

**檔案位置**：`lib/views/pages/notes/widgets/uploaded_photo_grid.dart`

### 8.5 快速標籤（QuickTagsSection）⭐ v3.1 新增

可選擇的快速標籤 Chip 列表：

```dart
QuickTagsSection(
  selectedTags: selectedTags,
  readOnly: false,
  onSelected: (tag, selected) => _handleTagToggle(tag, selected),
)
```

**設計規範**：
- 使用 `FilterChip`
- 支援唯讀模式
- Wrap 自動換行

**檔案位置**：`lib/views/pages/notes/widgets/quick_tags_section.dart`

---

## 9. 觸覺回饋

| 操作 | 觸覺類型 | 代碼 |
|------|---------|------|
| 完成組數 | 輕度撞擊 | `HapticFeedback.lightImpact()` |
| 計時結束 | 連續震動 | `HapticFeedback.vibrate()` |
| 滑動刪除 | 選擇點擊 | `HapticFeedback.selectionClick()` |
| 勾選 | 中度撞擊 | `HapticFeedback.mediumImpact()` |

---

## 10. 輸入模式適配 ⭐ v2.0 新增

### 10.1 觸控 vs 滑鼠

| 特性 | 觸控（手機/平板） | 滑鼠（桌面） |
|-----|-----------------|-------------|
| 觸控目標 | ≥ 48dp | 可縮小至 24dp |
| 懸停狀態 | 不需要 | 必須支援 |
| 輔助操作 | 長按、滑動 | 右鍵選單 |

### 10.2 Visual Density

```dart
// 桌面端：緊湊模式
ThemeData(
  visualDensity: VisualDensity.compact,
)

// 移動端：標準模式
ThemeData(
  visualDensity: VisualDensity.standard,
)
```

### 10.3 懸停效果

```dart
// 所有可互動元素必須支援懸停（桌面端）
InkWell(
  onTap: () => {},
  onHover: (hovering) {
    // 改變背景色或邊框
  },
  child: content,
)

// 或使用 MouseRegion
MouseRegion(
  cursor: SystemMouseCursors.click,
  child: content,
)
```

---

## 11. 開發檢查清單

### 基礎檢查（每次提交）

```
□ 所有間距都是 8 的倍數（或使用響應式間距）
□ 觸控目標最小 48dp
□ 深淺模式都測試過
□ 無溢出錯誤（黃黑條紋）
□ 數字欄位使用等寬字體
□ 關鍵操作有觸覺回饋
□ 文字可閱讀（字級、顏色）
□ 卡片圓角統一 20dp
```

### 響應式檢查 ⭐ v2.0 新增

```
□ 使用 context.responsive 或 Theme.textTheme 取代固定字體大小
□ 使用 context.spacing 或 context.pagePadding 取代固定間距
□ 禁止直接使用 MediaQuery.of(context).size.width
□ 在小螢幕（360dp）測試過佈局不溢出
□ 在大螢幕（1280dp+）測試過內容不過度拉伸
□ 列表頁面在大螢幕考慮多欄佈局
□ 桌面端可互動元素支援懸停狀態
```

---

## 相關文檔

- [UI_DESIGN_SYSTEM.md](UI_DESIGN_SYSTEM.md) - 設計理念
- [lib/themes/app_theme.dart](../lib/themes/app_theme.dart) - 主題實作
- [lib/utils/responsive/](../lib/utils/responsive/) - 響應式工具
- [planning/RESPONSIVE_ARCHITECTURE_DESIGN.md](planning/RESPONSIVE_ARCHITECTURE_DESIGN.md) - 響應式架構白皮書

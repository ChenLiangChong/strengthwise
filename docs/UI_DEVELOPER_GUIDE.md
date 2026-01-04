# StrengthWise - UI 開發指南

> 快速查表與代碼參考

**版本**：1.0  
**最後更新**：2026年1月5日

---

## 1. 色彩快查表

### 1.1 主要色彩

| 用途 | 淺色模式 | 深色模式 | Flutter 變數 |
|------|---------|---------|-------------|
| **Primary** | `#2563EB` | `#60A5FA` | `colorScheme.primary` |
| **On Primary** | `#FFFFFF` | `#0F172A` | `colorScheme.onPrimary` |
| **Secondary** | `#0D9488` | `#5EEAD4` | `colorScheme.secondary` |
| **Background** | `#F1F5F9` | `#0F172A` | `colorScheme.background` |
| **Surface** | `#FFFFFF` | `#1E293B` | `colorScheme.surface` |
| **On Surface** | `#0F172A` | `#F8FAFC` | `colorScheme.onSurface` |
| **Outline** | `#E2E8F0` | `#334155` | `colorScheme.outline` |

### 1.2 語意色彩

| 用途 | 淺色模式 | 深色模式 |
|------|---------|---------|
| **Success** | `#10B981` | `#34D399` |
| **Error** | `#EF4444` | `#EF4444` |
| **Warning** | `#F59E0B` | `#FBBF24` |

---

## 2. 字體快查表

### 2.1 字級系統（Material 3）

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

### 2.2 使用範例

```dart
// 數據顯示（等寬字體）
Text(
  '100.5',
  style: TextStyle(
    fontFamily: 'JetBrains Mono',
    fontSize: 20,
    fontWeight: FontWeight.w500,
  ),
)

// 一般標題
Text(
  '訓練記錄',
  style: theme.textTheme.headlineMedium,
)
```

---

## 3. 間距快查表（8 點網格）

| 規範名稱 | 數值 | 應用場景 |
|---------|------|---------|
| Micro | 4dp | 極小間距（文字與圖標） |
| Element | 8dp | 元素內部間距 |
| Card | 12dp | 卡片間距 |
| Container | 16dp | 頁面邊距、卡片內距 |
| Section | 24dp | 區塊分隔 |
| Large | 32dp | 大區塊分隔 |
| Touch Target | 48dp | 按鈕最小高度 |

### 使用範例

```dart
// ✅ 正確：使用 8 的倍數
SizedBox(height: 16)
Padding(padding: EdgeInsets.all(16))
Container(height: 48) // 觸控目標

// ❌ 錯誤：隨意數值
Padding(padding: EdgeInsets.all(13))
```

---

## 4. 圓角與陰影

### 4.1 圓角規範

| 元素 | 圓角 | 說明 |
|------|------|------|
| 卡片 | 12dp | 統一使用（非 16dp）|
| 按鈕 | 8dp 或 12dp | 取決於尺寸 |
| 輸入框 | 8dp | 標準輸入框 |
| 底部導航 | 0dp | 不使用圓角 |

### 4.2 陰影規範

| 模式 | 策略 | 說明 |
|------|------|------|
| 淺色模式 | `elevation: 0` + 邊框 | 使用邊框區分層次 |
| 深色模式 | `elevation: 0` | 用背景色差區分層次 |

```dart
// 淺色模式卡片
CardTheme(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: Color(0xFFE2E8F0)),
  ),
)

// 深色模式卡片
CardTheme(
  elevation: 0,
  color: Color(0xFF1E293B), // 比背景稍亮
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
)
```

---

## 5. 圖標規範

### 5.1 風格

- **描邊寬度**：1.5dp 或 2dp
- **未選中**：Outline（描邊）
- **選中**：Filled（實心）
- **推薦套件**：Hugeicons / Phosphor Icons

### 5.2 常用圖標

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

## 6. 組件規範

### 6.1 統一卡片（UnifiedSlotCard）

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

### 6.2 輸入框

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

---

## 7. 觸覺回饋

| 操作 | 觸覺類型 | 代碼 |
|------|---------|------|
| 完成組數 | 輕度撞擊 | `HapticFeedback.lightImpact()` |
| 計時結束 | 連續震動 | `HapticFeedback.vibrate()` |
| 滑動刪除 | 選擇點擊 | `HapticFeedback.selectionClick()` |
| 勾選 | 中度撞擊 | `HapticFeedback.mediumImpact()` |

---

## 8. 開發檢查清單

每次提交前檢查：

```
□ 所有間距都是 8 的倍數
□ 觸控目標最小 48dp
□ 深淺模式都測試過
□ 無溢出錯誤（黃黑條紋）
□ 數字欄位使用等寬字體
□ 關鍵操作有觸覺回饋
□ 文字可閱讀（字級、顏色）
□ 卡片圓角統一 12dp
```

---

## 相關文檔

- [UI_DESIGN_SYSTEM.md](UI_DESIGN_SYSTEM.md) - 設計理念
- [lib/themes/app_theme.dart](../lib/themes/app_theme.dart) - 主題實作


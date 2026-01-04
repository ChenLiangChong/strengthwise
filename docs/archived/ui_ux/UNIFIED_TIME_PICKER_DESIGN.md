# 統一時間設定模組設計文檔

**日期**：2026年1月2日  
**版本**：v2.0（修訂版）  
**狀態**：✅ 設計完成，部分實作中

---

## 📋 目標

基於實際場景需求與認知模型差異，採用**「選擇性統一」**策略：
- **視覺風格統一**：所有時間相關組件遵循 Material 3 設計規範
- **互動模式差異化**：根據使用情境選擇最適合的 UI 模式

---

## 🔍 現狀分析（修訂版）

### 實際四個時間設定場景

| 場景 | 位置 | 認知模型 | 時間類型 | 週期性 | 備註 | UI 模式 |
|------|------|---------|---------|-------|------|---------|
| **1. 學員時間偏好** | 學員中心 | 線性/時序 | 時間範圍 | ✅ 需要 | ✅ 需要 | 行事曆 + 對話框（已實作） |
| **2. 教練時段管理** | 教練中心 | 線性/時序 | 時間範圍 | ✅ 需要 | ✅ 需要 | 行事曆 + 對話框（已實作） |
| **3. 訓練計畫** | 新增訓練 | 數值 | 時間範圍 | ❌ 不需要 | ✅ 可選 | 系統原生（待實作） |
| **4. 模板設定** | 編輯模板 | - | ❌ 不需要 | ❌ 不需要 | ❌ 不需要 | 不儲存時間 |

### 關鍵洞察

#### 1. 模板不需要預設時間 ⭐
- **理由**：模板是「內容模板」（動作、組數、次數），不是「時間模板」
- **使用流程**：
  ```
  載入模板 → 創建訓練計畫 → 在計畫中設定時間
  ```
- **優點**：
  - 簡化用戶認知
  - 降低維護成本
  - 同一模板可在不同時間使用

#### 2. 場景 1、2 使用「行事曆 + 對話框」模式
- **為什麼不統一**：
  - 這是**線性/時序認知模型**
  - 用戶需要「看到一週的所有時段」（視覺化空檔）
  - 需要管理**多個時段**，彈出式選擇器效率低
  - 強調**衝突偵測**（哪些時段已被佔用）

- **現有實作**：`QuickAddSlotDialog`（已完整支援）
  - ✅ 日期（來自行事曆點擊，無需再選）
  - ✅ 開始/結束時間（系統原生 `showTimePicker`）
  - ✅ 週期性設定（每週/每天重複）
  - ✅ 備註（選填）

#### 3. 場景 3 使用「系統原生選擇器」
- **為什麼不同**：
  - 這是**數值認知模型**
  - 單次快速選擇，不需要視覺化
  - 不需要週期性功能
  - 追求效率和簡潔

---

## 🎯 修訂後的設計方案

## 🎯 修訂後的設計方案

### 設計理念：情境適應性統一

遵循權威分析報告的**「情境適應性精準度」**原則：
- 不強行統一所有場景的 UI
- 根據認知模型選擇最適合的互動模式
- 視覺風格統一，但互動邏輯差異化

---

## 🏗️ 實作架構

### 分層統一策略

```
視覺層（完全統一）⭐⭐⭐
  ├─ Material 3 設計規範
  ├─ 8 點網格系統
  ├─ 統一色彩、圓角、間距
  └─ 觸覺回饋（HapticFeedback）
    ↓
基礎組件層（部分統一）⭐⭐
  ├─ 系統原生 showTimePicker（時間點選擇）
  └─ 統一設計 Token（TimePickerDesignTokens）
    ↓
場景層（差異化）⭐
  ├─ 行事曆視圖（場景 1、2）
  │   └─ QuickAddSlotDialog（含週期性功能）
  ├─ 簡化時間範圍選擇器（場景 3）
  │   └─ 使用系統原生 TimePicker
  └─ 模板（場景 4）
      └─ 不儲存時間
```

---

## 📝 場景詳細設計

### 場景 1、2：學員時間偏好 + 教練時段管理

**不統一的理由**：
- 認知模型：線性/時序（需要視覺化時間軸）
- 用戶思維：「我這週哪些時段有空？」
- 關鍵需求：看到所有時段、識別空檔、避免衝突

**實作方案**：✅ 已完成

```dart
// 點擊行事曆日期後彈出
QuickAddSlotDialog(
  coachId: coachId,
  selectedDate: selectedDate, // 來自行事曆，無需再選
)

// 對話框包含：
// 1. 日期顯示（唯讀，來自行事曆）
// 2. 開始時間（系統原生 TimePicker）
// 3. 結束時間（系統原生 TimePicker）
// 4. 週期性設定（Switch + Radio）⭐
//    - 每週重複（FREQ=WEEKLY;BYDAY=MO）
//    - 每天重複（FREQ=DAILY）
// 5. 備註（選填，TextField）⭐
```

**視覺效果**：
```
┌──────────────────────────────┐
│ 新增時段                     │
│ 2026/1/2                     │
├──────────────────────────────┤
│ 開始時間  [09:00 AM] 🕐     │
│ 結束時間  [10:00 AM] 🕐     │
│                              │
│ 備註（選填）                 │
│ ┌──────────────────────┐    │
│ │ 例如：線上課程、小班制│    │
│ └──────────────────────┘    │
│                              │
│ 週期性時段  [ON/OFF]        │
│ ○ 每週  ● 每天              │
│                              │
│ ℹ️ 點擊下方按鈕添加到預約時段│
├──────────────────────────────┤
│ [取消]            [創建]    │
└──────────────────────────────┘
```

---

### 場景 3：訓練計畫

**需求**：
- 認知模型：數值（記錄精確時間）
- 用戶思維：「今天 6 點半開始練，練了 1.5 小時」
- 關鍵需求：快速輸入、精確到分鐘

**實作方案**：待實作

```dart
// 訓練計畫編輯頁面
class WorkoutPlanEditor extends StatelessWidget {
  DateTime? _trainingTime;      // 開始時間
  DateTime? _trainingEndTime;   // 結束時間 ⭐

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 日期選擇（必須）
        DatePickerField(
          label: '訓練日期',
          value: _scheduledDate,
          onTap: () async {
            final date = await showDatePicker(...);
            if (date != null) {
              setState(() => _scheduledDate = date);
            }
          },
        ),
        
        // 開始時間（可選）
        TimePickerField(
          label: '開始時間',
          value: _trainingTime,
          onTap: () async {
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    alwaysUse24HourFormat: true,
                  ),
                  child: child!,
                );
              },
            );
            if (time != null) {
              setState(() {
                _trainingTime = DateTime(
                  _scheduledDate.year,
                  _scheduledDate.month,
                  _scheduledDate.day,
                  time.hour,
                  time.minute,
                );
              });
            }
          },
        ),
        
        // 結束時間（可選）⭐
        if (_trainingTime != null)
          TimePickerField(
            label: '結束時間',
            value: _trainingEndTime,
            onTap: () async {
              final time = await showTimePicker(...);
              if (time != null) {
                setState(() {
                  _trainingEndTime = DateTime(
                    _scheduledDate.year,
                    _scheduledDate.month,
                    _scheduledDate.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            },
          ),
          
        // 顯示時長（自動計算）
        if (_trainingTime != null && _trainingEndTime != null)
          Text(
            '時長：${_calculateDuration()}',
            style: TextStyle(color: Colors.grey[600]),
          ),
      ],
    );
  }
  
  String _calculateDuration() {
    final duration = _trainingEndTime!.difference(_trainingTime!);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0 && minutes > 0) {
      return '$hours 小時 $minutes 分鐘';
    } else if (hours > 0) {
      return '$hours 小時';
    } else {
      return '$minutes 分鐘';
    }
  }
}
```

**關鍵特點**：
- ✅ 使用系統原生 `showTimePicker`（用戶熟悉）
- ✅ 自動適配深淺模式
- ✅ 支援 24 小時制
- ✅ 自動計算時長
- ❌ 不需要週期性功能（訓練記錄是單次事件）
- ❌ 不需要行事曆視圖（單筆記錄，不需視覺化）

---

### 場景 4：模板

**結論**：❌ 不儲存時間

**理由**：
1. 模板的定義：**內容模板**（動作、組數、次數），不是時間模板
2. 時間的多變性：同一個「胸推模板」，週一可能晚上練，週三可能下午練
3. 簡化用戶認知：模板 = 動作清單，計畫 = 模板 + 時間 + 日期

**使用流程**：
```
用戶：「今天練胸」
  ↓
載入「胸推訓練」模板
  ↓
系統：「今天幾點訓練？」← 在創建計畫時選時間
  ↓
創建訓練計畫（帶日期 + 時間範圍）
```

---

## 🎨 視覺設計統一規範

### 統一設計 Token

## 🎨 視覺設計統一規範

### 統一設計 Token

所有時間相關組件都應使用這些設計 Token：

```dart
/// 時間選擇器設計 Token
class TimePickerDesignTokens {
  // 間距
  static const double borderRadius = 12.0;
  static const double spacing = 8.0;
  static const double sectionSpacing = 16.0;
  static const double dialogPadding = 24.0;
  
  // 觸控目標
  static const double touchTargetSize = 48.0;
  
  // 動畫
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve animationCurve = Curves.easeInOut;
  
  // 字體（時間顯示使用等寬字體）
  static const TextStyle timeTextStyle = TextStyle(
    fontFamily: 'JetBrains Mono',
    fontWeight: FontWeight.bold,
    fontSize: 18,
  );
  
  // 標籤字體
  static const TextStyle labelTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  // 輔助文字
  static const TextStyle hintTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
}
```

### Material 3 設計規範

#### 1. 色彩使用
- **主色 (Primary)**：確認按鈕、選中狀態
- **表面色 (Surface)**：對話框背景、卡片
- **輪廓色 (Outline)**：邊框、分隔線
- **錯誤色 (Error)**：時間驗證失敗

#### 2. 圓角統一
- 對話框：16dp
- 輸入框：12dp
- 按鈕：8dp
- 晶片 (Chips)：20dp（全圓角）

#### 3. 間距系統（8dp 網格）
- 小間距：8dp
- 標準間距：16dp
- 區塊間距：24dp
- 對話框內邊距：24dp

#### 4. 觸覺回饋

所有時間相關操作都應加入觸覺回饋：

```dart
// 選擇時間時
HapticFeedback.selectionClick();

// 確認時段時
HapticFeedback.mediumImpact();

// 錯誤提示時
HapticFeedback.heavyImpact();
```

---

## 📋 實作檢查清單

### Phase 1：場景 1、2 優化（✅ 已完成）

- [x] 修復 `QuickAddSlotDialog`
  - [x] 加入週期性設定（Switch + Radio）
  - [x] 確保備註欄位正常運作
  - [x] 使用系統原生 `showTimePicker`
  - [x] 支援 24 小時制

### Phase 2：場景 3 實作（待完成）

- [ ] 訓練計畫編輯器
  - [ ] 日期選擇（`showDatePicker`）
  - [ ] 開始時間（`showTimePicker`）
  - [ ] 結束時間（`showTimePicker`）
  - [ ] 自動計算時長顯示
  - [ ] 儲存到 `WorkoutRecord` 模型

### Phase 3：場景 4 清理（待完成）

- [ ] 移除模板的時間欄位
  - [ ] 標記 `WorkoutTemplate.trainingTime` 為 `@deprecated`
  - [ ] 確認不影響現有邏輯
  - [ ] 更新相關文檔

### Phase 4：視覺統一（待完成）

- [ ] 建立 `TimePickerDesignTokens`
- [ ] 統一所有時間選擇組件的視覺風格
- [ ] 加入觸覺回饋
- [ ] 深淺模式測試

---

## ✅ 優點總結

### 1. 符合認知模型
- **場景 1、2**：線性/時序模型 → 行事曆視圖
- **場景 3**：數值模型 → 系統原生選擇器
- **場景 4**：不儲存時間 → 簡化認知

### 2. 實用性優先
- 使用用戶熟悉的系統原生組件
- 根據設備能力選擇最佳互動模式
- 不強行統一，而是適應情境

### 3. 視覺統一
- Material 3 設計規範
- 統一的設計 Token
- 一致的色彩、圓角、間距

### 4. 易於維護
- 使用系統原生組件（維護成本低）
- 清晰的分層架構
- 完整的文檔記錄

---

## 🔄 與權威分析報告的對應

本設計方案完全遵循報告的核心原則：

### 1. 情境適應性精準度 ✅
> 「反對一體適用（One-size-fits-all）的過時策略」

- 場景 1、2：視覺化行事曆（線性模型）
- 場景 3：快速輸入（數值模型）
- 場景 4：不儲存時間（簡化認知）

### 2. 互動成本最小化 ✅
> 「評估實用性的黃金標準是互動成本」

- 使用系統原生組件（用戶零學習成本）
- 點擊行事曆自動帶入日期（減少步驟）
- 自動計算時長（減少認知負荷）

### 3. 跨平台適應性 ✅
> 「強行統一多端設計是 UI/UX 開發中最大的陷阱」

- 系統原生組件自動適配平台
- 觸覺回饋僅在支援的設備啟用
- 響應式佈局適應不同屏幕

### 4. 無障礙設計 ✅
> 「專業的 UI 必須考慮所有使用者」

- 系統原生組件內建無障礙支援
- 觸控目標最小 48dp
- 支援鍵盤導航（Tab、Enter、Esc）

---

## 📚 相關文檔

- **[docs/UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 開發狀態
- **[AGENTS.md](../AGENTS.md)** - AI 開發指南

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2026年1月2日

---

## 附錄 A：廢棄的統一方案（供參考）

以下內容為原始設計方案，已證實不符合實際需求：

### ❌ 問題：強行統一所有場景

原始設計嘗試建立一個「萬能」的 `UnifiedTimePicker`：
  
  TimeRange({
    required this.start,
    required this.end,
  }) : assert(!_isEndBeforeStart(start, end));
  
  /// 時長（分鐘）
  int get durationInMinutes {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes - startMinutes;
  }
  
  /// 格式化顯示：「09:00 - 10:30 (1.5 小時)」
  String format(BuildContext context) {
    final duration = Duration(minutes: durationInMinutes);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    String durationText;
    if (hours > 0 && minutes > 0) {
      durationText = '$hours 小時 $minutes 分鐘';
    } else if (hours > 0) {
      durationText = '$hours 小時';
    } else {
      durationText = '$minutes 分鐘';
    }
    
    return '${start.format(context)} - ${end.format(context)} ($durationText)';
  }
  
  static bool _isEndBeforeStart(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes <= startMinutes;
  }
}
```

---

### 2. 快捷選項模型 (QuickOption)

```dart
/// 快捷時間選項
class QuickTimeOption {
  final String label;          // 顯示文字：「早上」、「下午」
  final TimeRange timeRange;   // 時間範圍
  final IconData? icon;        // 圖標（可選）
  
  QuickTimeOption({
    required this.label,
    required this.timeRange,
    this.icon,
  });
  
  /// 預設快捷選項
  static List<QuickTimeOption> get defaults => [
    QuickTimeOption(
      label: '早上',
      icon: Icons.wb_twilight,
      timeRange: TimeRange(
        start: const TimeOfDay(hour: 6, minute: 0),
        end: const TimeOfDay(hour: 9, minute: 0),
      ),
    ),
    QuickTimeOption(
      label: '上午',
      icon: Icons.wb_sunny,
      timeRange: TimeRange(
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 12, minute: 0),
      ),
    ),
    QuickTimeOption(
      label: '下午',
      icon: Icons.wb_cloudy,
      timeRange: TimeRange(
        start: const TimeOfDay(hour: 14, minute: 0),
        end: const TimeOfDay(hour: 17, minute: 0),
      ),
    ),
    QuickTimeOption(
      label: '晚上',
      icon: Icons.nights_stay,
      timeRange: TimeRange(
        start: const TimeOfDay(hour: 18, minute: 0),
        end: const TimeOfDay(hour: 21, minute: 0),
      ),
    ),
  ];
}
```

---

### 3. 統一時間選擇器 (UnifiedTimePicker)

```dart
/// 統一時間選擇器
class UnifiedTimePicker {
  /// 選擇單一時間點
  /// 
  /// 使用系統原生 TimePicker
  static Future<TimeOfDay?> pickTime(
    BuildContext context, {
    required TimeOfDay initialTime,
    String? helpText,
  }) async {
    return showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: helpText ?? '選擇時間',
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: true,  // 統一使用 24 小時制
          ),
          child: child!,
        );
      },
    );
  }
  
  /// 選擇時間段（開始 + 結束）
  /// 
  /// 顯示自定義底部表單，包含：
  /// - 快捷選項（可選）
  /// - 開始/結束時間選擇
  /// - 時長顯示
  static Future<TimeRange?> pickTimeRange(
    BuildContext context, {
    required TimeOfDay initialStart,
    TimeOfDay? initialEnd,
    Duration? defaultDuration,
    List<QuickTimeOption>? quickOptions,
    String? title,
  }) async {
    return showModalBottomSheet<TimeRange>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TimeRangePickerSheet(
        initialStart: initialStart,
        initialEnd: initialEnd ?? _calculateDefaultEnd(initialStart, defaultDuration),
        quickOptions: quickOptions ?? QuickTimeOption.defaults,
        title: title,
      ),
    );
  }
  
  /// 計算預設結束時間
  static TimeOfDay _calculateDefaultEnd(TimeOfDay start, Duration? duration) {
    final defaultDuration = duration ?? const Duration(hours: 1);
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = startMinutes + defaultDuration.inMinutes;
    
    return TimeOfDay(
      hour: (endMinutes ~/ 60) % 24,
      minute: endMinutes % 60,
    );
  }
}
```

---

### 4. 時段選擇底部表單 (TimeRangePickerSheet)

```dart
/// 時段選擇底部表單
class TimeRangePickerSheet extends StatefulWidget {
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final List<QuickTimeOption> quickOptions;
  final String? title;
  
  const TimeRangePickerSheet({
    super.key,
    required this.initialStart,
    required this.initialEnd,
    this.quickOptions = const [],
    this.title,
  });

  @override
  State<TimeRangePickerSheet> createState() => _TimeRangePickerSheetState();
}

class _TimeRangePickerSheetState extends State<TimeRangePickerSheet> {
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startTime = widget.initialStart;
    _endTime = widget.initialEnd;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeRange = TimeRange(start: _startTime, end: _endTime);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 標題
            Text(
              widget.title ?? '選擇時段',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // 快捷選項（可選）⭐
            if (widget.quickOptions.isNotEmpty) ...[
              QuickTimeOptions(
                options: widget.quickOptions,
                onSelected: (option) {
                  setState(() {
                    _startTime = option.timeRange.start;
                    _endTime = option.timeRange.end;
                    _errorMessage = null;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],
            
            // 開始時間
            _TimePickerField(
              label: '開始時間',
              time: _startTime,
              onTap: () async {
                final time = await UnifiedTimePicker.pickTime(
                  context,
                  initialTime: _startTime,
                  helpText: '選擇開始時間',
                );
                if (time != null) {
                  setState(() {
                    _startTime = time;
                    _validateTimeRange();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 結束時間
            _TimePickerField(
              label: '結束時間',
              time: _endTime,
              onTap: () async {
                final time = await UnifiedTimePicker.pickTime(
                  context,
                  initialTime: _endTime,
                  helpText: '選擇結束時間',
                );
                if (time != null) {
                  setState(() {
                    _endTime = time;
                    _validateTimeRange();
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 時長顯示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '時長：${_formatDuration(timeRange.durationInMinutes)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // 錯誤訊息
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // 按鈕
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _errorMessage == null
                        ? () => Navigator.pop(context, timeRange)
                        : null,
                    child: const Text('確定'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 驗證時間範圍
  void _validateTimeRange() {
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (endMinutes <= startMinutes) {
      setState(() {
        _errorMessage = '結束時間必須晚於開始時間';
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
    }
  }

  /// 格式化時長
  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    
    if (hours > 0 && mins > 0) {
      return '$hours 小時 $mins 分鐘';
    } else if (hours > 0) {
      return '$hours 小時';
    } else {
      return '$mins 分鐘';
    }
  }
}

/// 時間選擇欄位
class _TimePickerField extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePickerField({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time.format(context),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrains Mono', // 等寬字體
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 5. 快捷選項組件 (QuickTimeOptions)

```dart
/// 快捷時間選項組件
class QuickTimeOptions extends StatelessWidget {
  final List<QuickTimeOption> options;
  final Function(QuickTimeOption) onSelected;

  const QuickTimeOptions({
    super.key,
    required this.options,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '快速選擇',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            return _QuickOptionChip(
              option: option,
              onTap: () => onSelected(option),
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// 快捷選項按鈕
class _QuickOptionChip extends StatelessWidget {
  final QuickTimeOption option;
  final VoidCallback onTap;

  const _QuickOptionChip({
    required this.option,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.primary.withOpacity(0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(
                option.icon,
                size: 16,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              option.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 🔄 四個場景的統一遷移方案

### 1. 學員時間偏好（Client Availability）

**原實作**：`AvailabilitySlotEditorDialog`

**遷移後**：
```dart
// 新增/編輯時段
Future<void> _showAddSlotDialog() async {
  final timeRange = await UnifiedTimePicker.pickTimeRange(
    context,
    initialStart: TimeOfDay.now(),
    defaultDuration: const Duration(hours: 1),
    quickOptions: QuickTimeOption.defaults,  // 使用預設快捷選項
    title: '新增時間偏好',
  );
  
  if (timeRange != null) {
    // 保存時段邏輯
  }
}
```

---

### 2. 教練時段管理（Coach Availability Slots）

**原實作**：`AddSlotDialog` / `QuickAddSlotDialog`

**遷移後**：
```dart
// 新增可用時段
Future<void> _showAddSlotDialog() async {
  final timeRange = await UnifiedTimePicker.pickTimeRange(
    context,
    initialStart: const TimeOfDay(hour: 9, minute: 0),
    defaultDuration: const Duration(minutes: 60),
    quickOptions: QuickTimeOption.defaults,
    title: '新增可用時段',
  );
  
  if (timeRange != null) {
    // 創建時段邏輯
  }
}
```

---

### 3. 訓練計畫（Workout Plan Editor）

**原實作**：`TrainingTimePickerDialog`

**遷移後**：
```dart
// 選擇訓練開始時間
Future<void> _selectTrainingStartTime() async {
  final time = await UnifiedTimePicker.pickTime(
    context,
    initialTime: TimeOfDay.fromDateTime(_trainingTime),
    helpText: '選擇訓練開始時間',
  );
  
  if (time != null) {
    setState(() {
      _trainingTime = DateTime(
        _trainingTime.year,
        _trainingTime.month,
        _trainingTime.day,
        time.hour,
        time.minute,
      );
    });
  }
}

// 或選擇訓練時段
Future<void> _selectTrainingTimeRange() async {
  final timeRange = await UnifiedTimePicker.pickTimeRange(
    context,
    initialStart: TimeOfDay.fromDateTime(_trainingTime),
    initialEnd: TimeOfDay.fromDateTime(_trainingEndTime),
    title: '選擇訓練時段',
  );
  
  if (timeRange != null) {
    setState(() {
      _trainingTime = DateTime(
        _trainingTime.year,
        _trainingTime.month,
        _trainingTime.day,
        timeRange.start.hour,
        timeRange.start.minute,
      );
      _trainingEndTime = DateTime(
        _trainingTime.year,
        _trainingTime.month,
        _trainingTime.day,
        timeRange.end.hour,
        timeRange.end.minute,
      );
    });
  }
}
```

---

### 4. 模板設定（Template Editor）

**新增功能**：
```dart
// 設定預設訓練時段
Future<void> _selectDefaultTime() async {
  final timeRange = await UnifiedTimePicker.pickTimeRange(
    context,
    initialStart: const TimeOfDay(hour: 18, minute: 0),
    defaultDuration: const Duration(hours: 1, minutes: 30),
    quickOptions: QuickTimeOption.defaults,
    title: '預設訓練時段',
  );
  
  if (timeRange != null) {
    setState(() {
      _defaultStartTime = timeRange.start;
      _defaultEndTime = timeRange.end;
    });
  }
}
```

---

## 🎨 UI/UX 設計規範

### 遵循 Material 3

- ✅ 使用系統原生組件（`showTimePicker`）
- ✅ 深淺模式自動適配
- ✅ 統一圓角（12dp）
- ✅ 統一間距（8dp 網格）
- ✅ 觸控目標最小 48dp

### 觸覺回饋

```dart
// 在確認時間時添加觸覺回饋
HapticFeedback.mediumImpact();
```

### 無障礙

```dart
Semantics(
  label: '選擇開始時間',
  hint: '點擊打開時間選擇器',
  child: _TimePickerField(...),
)
```

---

## ✅ 優點總結

1. **統一體驗**：所有場景使用一致的 UI
2. **代碼復用**：減少重複代碼
3. **易於維護**：統一入口，統一修改
4. **符合規範**：遵循 Material 3 設計
5. **靈活擴展**：支援自定義快捷選項
6. **用戶友善**：系統原生 + 快捷選項

---

## 📋 實作步驟

### Phase 1：建立基礎組件（1 天）
1. ✅ 創建 `TimeRange` 和 `QuickTimeOption` 模型
2. ✅ 實作 `UnifiedTimePicker` 靜態類別
3. ✅ 實作 `TimeRangePickerSheet` 底部表單
4. ✅ 實作 `QuickTimeOptions` 組件

### Phase 2：遷移現有場景（2 天）
1. ✅ 遷移學員時間偏好
2. ✅ 遷移教練時段管理
3. ✅ 遷移訓練計畫編輯器
4. ✅ 新增模板時間設定

### Phase 3：測試與優化（1 天）
1. ✅ 深淺模式測試
2. ✅ 不同屏幕尺寸測試
3. ✅ 無障礙測試
4. ✅ 性能測試

---

**總計時間**：4 天

---

## 📚 相關文檔

- **[docs/UI_UX_GUIDELINES.md](UI_UX_GUIDELINES.md)** - UI/UX 設計規範
- **[docs/DEVELOPMENT_STATUS.md](DEVELOPMENT_STATUS.md)** - 開發狀態

---

**維護者**：StrengthWise 開發團隊  
**最後更新**：2026年1月2日


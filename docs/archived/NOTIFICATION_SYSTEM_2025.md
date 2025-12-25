# StrengthWise 通知系統 2025 升級指南

> 從基礎通知到專業級自適應通知的完整遷移指南

**最後更新**：2024 年 12 月 26 日

---

## 📊 升級概覽

### ✅ 已完成升級

| 升級項目 | 狀態 | 說明 |
|---------|------|------|
| **elegant_notification 套件** | ✅ 完成 | 頂部動態島風格通知 |
| **flutter_animate 套件** | ✅ 完成 | 微動畫支援（圖示路徑追蹤） |
| **AdaptiveNotificationService** | ✅ 完成 | 情境自適應通知服務 |
| **RestTimerOverlay** | ✅ 完成 | 頂部動態島風格計時器 |
| **玻璃擬態視覺** | ✅ 完成 | 圓角膠囊（24px）+ 半透明 |
| **深淺色模式優化** | ✅ 完成 | 低飽和度色彩系統 |
| **觸覺回饋** | ✅ 完成 | 所有通知伴隨震動 |
| **微動畫** | ✅ 完成 | Scale + Shimmer + Fade |

---

## 🎯 通知系統架構

### 📁 新增文件

```
lib/
├── utils/
│   ├── notification_utils.dart         # 基礎通知（已升級）
│   └── adaptive_notification_service.dart  # 進階自適應通知 ⭐ NEW
└── widgets/
    └── rest_timer_overlay.dart         # 動態島計時器 ⭐ NEW
```

---

## 🔄 遷移指南

### 方案 1：最小化遷移（保留舊代碼）

**適用場景**：現有代碼量大，希望漸進式升級

**步驟**：
1. 保留所有現有 `NotificationUtils` 調用
2. 僅在新功能中使用 `AdaptiveNotificationService`

**優點**：
- ✅ 零破壞性
- ✅ 立即享受新視覺風格（膠囊形狀 + 觸覺回饋）
- ✅ 逐步遷移，風險低

**範例**：
```dart
// 舊代碼（無需修改，已自動升級視覺風格）
NotificationUtils.showSuccess(context, '記錄已儲存');

// 新功能（使用進階服務）
AdaptiveNotificationService.showSuccess(context, '打破個人紀錄！');
```

---

### 方案 2：全面遷移（推薦）

**適用場景**：希望獲得最佳 UX 體驗（鍵盤自適應、平台差異化）

**對照表**：

| 舊方法（NotificationUtils） | 新方法（AdaptiveNotificationService） | 備註 |
|---------------------------|-------------------------------------|------|
| `showSuccess()` | `showSuccess()` | 新增鍵盤偵測 + iOS 頂部通知 |
| `showError()` | `showError()` | 始終頂部（系統級） |
| `showInfo()` | `showInfo()` | 新增鍵盤自適應 |
| `showWarning()` | `showWarning()` | 頂部，中度震動 |
| ❌ 無 | `showUndoableAction()` ⭐ NEW | 強制底部 + 撤銷按鈕 |
| ❌ 無 | `showAchievement()` ⭐ NEW | 頂部大型 Banner + 金色 |
| ❌ 無 | `showSystemStatus()` ⭐ NEW | 頂部 Sticky + 持續顯示 |

---

## 💡 使用場景與範例

### 場景 1：高頻操作（記錄訓練組數）

**推薦**：底部 Snackbar

```dart
// 使用基礎版（底部）
NotificationUtils.showSuccess(context, '組數 +1');

// 或使用進階版（自動適配）
AdaptiveNotificationService.showSuccess(
  context,
  '組數 +1',
  forceBottom: true, // 強制底部（拇指熱區）
);
```

**視覺效果**：
- 🎨 深灰膠囊（深色模式）或孔雀藍綠（淺色模式）
- ✅ 勾選圖示 + Scale 動畫
- 📳 輕度觸覺回饋
- ⏱️ 3 秒自動消失

---

### 場景 2：可撤銷操作（刪除訓練記錄）

**推薦**：底部 Snackbar + UNDO 按鈕 ⭐

```dart
AdaptiveNotificationService.showUndoableAction(
  context,
  '已刪除訓練記錄',
  onUndo: () {
    // 恢復數據
    _workoutService.restoreRecord(deletedRecord);
  },
  duration: const Duration(seconds: 7), // 延長以便操作
);
```

**視覺效果**：
- 🎨 反色設計（深色 App 顯示淺色 Toast）
- 🔄 顯眼的「撤銷」按鈕（位於拇指熱區）
- 📳 中度觸覺回饋
- ⏱️ 7 秒（延長）

---

### 場景 3：鍵盤開啟時的輸入錯誤

**推薦**：自動切換頂部通知 ⭐

```dart
// 無需手動判斷，自動偵測鍵盤
AdaptiveNotificationService.showError(
  context,
  '重量格式錯誤，請輸入數字',
);
```

**行為**：
- ✅ 自動偵測 `MediaQuery.of(context).viewInsets.bottom > 0`
- 🔝 鍵盤開啟時 → 頂部通知（避開鍵盤）
- 📳 重度觸覺回饋
- ⏱️ 4 秒

---

### 場景 4：重大成就（打破個人紀錄）⭐

**推薦**：頂部大型 Banner + 金色

```dart
AdaptiveNotificationService.showAchievement(
  context,
  '🎉 恭喜！',
  '臥推重量打破個人紀錄：120kg',
  icon: Icons.emoji_events_rounded,
  duration: const Duration(seconds: 4),
);
```

**視覺效果**：
- 🎨 金色背景（深色模式：`#FCD34D`，淺色模式：`#F59E0B`）
- 🏆 大型圖示（32px）
- ✨ Shimmer 微光動畫
- 📳 連續兩次重度震動（多巴胺刺激）
- ⏱️ 4 秒（值得打斷心流）

---

### 場景 5：系統狀態（網路斷線）⭐

**推薦**：頂部 Sticky Pill

```dart
AdaptiveNotificationService.showSystemStatus(
  context,
  '網路已斷線',
  icon: Icons.cloud_off_outlined,
  color: const Color(0xFFEF4444), // 紅色
);

// 需手動關閉（當網路恢復時）
// 注意：目前版本會自動消失，如需持續顯示，需使用 Overlay
```

**視覺效果**：
- 🎨 紅色/黃色窄版膠囊（頂部居中）
- 🔴 持續顯示（系統級）
- 📳 中度觸覺回饋
- ⏱️ 極長時間（需手動關閉）

---

### 場景 6：休息計時器（動態島風格）⭐⭐⭐

**推薦**：頂部動態島 Overlay

```dart
// 開始休息計時
RestTimerOverlay.show(
  context,
  durationInSeconds: 90, // 90 秒休息
  onComplete: () {
    // 計時結束回調
    AdaptiveNotificationService.showSuccess(
      context,
      '休息結束！準備開始下一組',
    );
  },
);

// 手動關閉（如果使用者想提前結束）
RestTimerOverlay.hide();

// 檢查是否正在運行
if (RestTimerOverlay.isRunning) {
  print('剩餘時間：${RestTimerOverlay.remainingSeconds} 秒');
}
```

**視覺效果**：
- 🎨 黑色膠囊（深色模式：`#1E293B`，淺色模式：`#334155`）
- ⏱️ 實時倒數（`01:30`）
- 👆 點擊展開/收合（彈性動畫）
- ✨ 計時結束時變綠色 + 連續震動
- 📍 持續顯示在頂部，不影響其他操作

**展開狀態**：
```
┌─────────────────────────────┐
│        [⏱️ 圖示]             │
│                              │
│        01:30                 │
│                              │
│     剩餘休息時間              │
└─────────────────────────────┘
```

**收合狀態**：
```
┌──────────────────┐
│ ⏱️  01:30   ✕   │
└──────────────────┘
```

---

## 🎨 視覺規範對照

### 深淺色模式色彩系統

| 通知類型 | 深色模式背景 | 淺色模式背景 | 文字顏色 |
|---------|------------|------------|---------|
| **成功** | `#81C784`（粉綠） | `#0D9488`（孔雀藍綠） | 深色模式：`#0F172A`<br>淺色模式：`#FFFFFF` |
| **錯誤** | `#EF4444`（鮮紅） | `#EF4444`（鮮紅） | `#FFFFFF` |
| **資訊** | `#38BDF8`（電光藍） | `#2563EB`（皇家藍） | `#FFFFFF` |
| **警告** | `tertiary`（主題） | `tertiary`（主題） | `onTertiary` |
| **成就** | `#FCD34D`（金色） | `#F59E0B`（琥珀色） | 深色模式：`#0F172A`<br>淺色模式：`#FFFFFF` |

**關鍵原則**：
1. **避免高飽和度**：深色模式使用低飽和度（`#81C784` 而非 `#00FF00`）
2. **反色設計**：可撤銷操作使用反色（深色 App 顯示淺色 Toast）
3. **對比度**：確保 WCAG AAA 標準（4.5:1）

---

## 🔧 進階配置

### 自訂成功色（覆寫主題色）

如果想統一使用綠色而非主題色：

```dart
// 修改 lib/utils/adaptive_notification_service.dart
// Line 414: _showBottomSuccessSnackbar()

backgroundColor: const Color(0xFF2E7D32), // 強制深綠色
```

### 調整通知顯示時長

```dart
// 全域設定（修改 AdaptiveNotificationService 內的預設值）
toastDuration: duration ?? const Duration(seconds: 3), // 改為 4 秒

// 單次調用設定
AdaptiveNotificationService.showSuccess(
  context,
  '保存成功',
  duration: const Duration(seconds: 5), // 自訂 5 秒
);
```

### 修改膠囊圓角大小

```dart
// 在 AdaptiveNotificationService 或 NotificationUtils 中
// 搜尋 borderRadius: BorderRadius.circular(24)
// 修改為想要的數值（建議 20-28 之間）

shape: RoundedRectangleBorder(
  borderRadius: BorderRadius.circular(20), // 改為 20
),
```

---

## 🧪 測試檢查清單

### ✅ 視覺測試

- [ ] 深色模式：所有通知可清晰閱讀
- [ ] 淺色模式：所有通知可清晰閱讀
- [ ] 膠囊形狀：左右留白 16dp，圓角 24dp
- [ ] 底部通知：不遮擋底部導航欄（margin bottom: 80）
- [ ] 頂部通知：不遮擋 AppBar 或狀態列

### ✅ 互動測試

- [ ] 成功通知：輕度震動（`lightImpact`）
- [ ] 錯誤通知：重度震動（`heavyImpact`）
- [ ] 撤銷按鈕：點擊有效，位於拇指熱區
- [ ] 鍵盤開啟時：通知自動切換頂部
- [ ] 休息計時器：點擊展開/收合流暢

### ✅ 動畫測試

- [ ] 圖示路徑動畫：勾選圖示有 scale + shimmer
- [ ] 入場動畫：通知從頂部/底部滑入
- [ ] 成就通知：金色光澤 + 大型圖示

### ✅ 無障礙測試

- [ ] 螢幕閱讀器：VoiceOver/TalkBack 可讀取通知內容
- [ ] 減少動效模式：尊重系統設定（待實作）
- [ ] 高對比度模式：色彩符合 WCAG AAA

---

## 📚 相關文檔

- **設計規範**：`docs/UI_UX_GUIDELINES.md`
- **色彩系統**：`lib/themes/app_theme.dart`
- **2025 最佳實踐**：參考使用者提供的 20,000 字研究報告

---

## 🎯 下一步計畫

### P1 優先級

- [ ] **減少動效適配**：檢測 `MediaQuery.of(context).disableAnimations`
- [ ] **螢幕閱讀器優化**：為所有通知添加 `Semantics` Widget
- [ ] **持續性系統狀態**：改用 Overlay 實作真正的 Sticky 通知

### P2 次要功能

- [ ] **批量通知管理**：一次關閉多個通知
- [ ] **通知歷史記錄**：查看最近 10 條通知
- [ ] **音效支援**：可選的成功/錯誤提示音

---

## 🙏 致謝

本次升級基於 **2025 年行動應用程式成功通知佈局與 UX 最佳實踐深入研究報告**，特別感謝該報告對以下理論的深入分析：

- 費茨定律（Fitts's Law）與拇指熱區
- 操作制約（Operant Conditioning）與正向增強
- iOS 動態島（Dynamic Island）的設計範式轉移
- 玻璃擬態（Glassmorphism）與 2025 年視覺趨勢

---

**版本**：v2.0.0  
**最後更新**：2024-12-26  
**維護者**：StrengthWise 開發團隊


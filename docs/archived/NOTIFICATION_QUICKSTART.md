# 🚀 通知系統 2025 快速開始

> 5 分鐘快速上手指南

---

## 📦 第一步：安裝依賴（已完成 ✅）

```bash
flutter pub get
```

---

## 💡 第二步：選擇使用方式

### 方式 A：保持現有代碼不變（最簡單）

**所有現有的 `NotificationUtils` 調用已自動升級！**

```dart
// 無需修改，已享受新視覺：
NotificationUtils.showSuccess(context, '記錄已儲存');
// ✅ 圓角膠囊 + 觸覺回饋 + 玻璃擬態
```

---

### 方式 B：使用進階功能（推薦）

#### 1. 導入服務

```dart
import 'package:strengthwise/utils/adaptive_notification_service.dart';
import 'package:strengthwise/widgets/rest_timer_overlay.dart';
```

#### 2. 選擇合適的通知類型

##### 常規操作（記錄數據）
```dart
AdaptiveNotificationService.showSuccess(context, '記錄已儲存');
```

##### 可撤銷操作（刪除）⭐
```dart
AdaptiveNotificationService.showUndoableAction(
  context,
  '已刪除訓練記錄',
  onUndo: () {
    // 恢復數據
    workoutService.restoreRecord(deletedRecord);
  },
);
```

##### 重大成就（PR）⭐⭐
```dart
AdaptiveNotificationService.showAchievement(
  context,
  '🎉 恭喜！',
  '臥推重量打破個人紀錄：120kg',
);
```

##### 休息計時器（動態島）⭐⭐⭐
```dart
RestTimerOverlay.show(
  context,
  durationInSeconds: 90,
  onComplete: () {
    AdaptiveNotificationService.showSuccess(
      context,
      '休息結束！準備開始下一組',
    );
  },
);
```

---

## 🧪 第三步：測試（可選）

### 打開測試頁面

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const NotificationTestPage(),
  ),
);
```

或在 `main.dart` 添加路由：

```dart
'/notification-test': (context) => const NotificationTestPage(),
```

---

## 📊 功能對照表

| 需求 | 使用方法 | 位置 | 特點 |
|------|---------|------|------|
| 記錄數據 | `showSuccess()` | 底部 | 快速確認 |
| 刪除操作 | `showUndoableAction()` | 底部 | 可撤銷 |
| 錯誤提示 | `showError()` | 頂部 | 系統級 |
| 重大成就 | `showAchievement()` | 頂部 | 金色 Banner |
| 休息計時 | `RestTimerOverlay.show()` | 頂部 | 動態島風格 |

---

## 📚 完整文檔

- **詳細指南**：`docs/NOTIFICATION_SYSTEM_2025.md`
- **升級報告**：`docs/NOTIFICATION_UPGRADE_REPORT.md`
- **UI/UX 規範**：`docs/UI_UX_GUIDELINES.md`

---

**就這麼簡單！開始享受 2025 年專業級通知體驗吧！** 🎉


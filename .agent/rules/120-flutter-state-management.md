---
description: "狀態管理規範：Provider、ChangeNotifier、GetIt 使用指南。適用於 Controller 和 Service 層。"
globs: lib/controllers/**/*.dart,lib/services/**/*.dart
alwaysApply: false
---

# 狀態管理規範

<critical>
1. Controller 必須繼承 `ChangeNotifier`
2. 狀態變更後必須呼叫 `notifyListeners()`
3. 禁止在 `build()` 中呼叫異步方法
4. 禁止直接修改列表（必須重新賦值）
</critical>

## ✅ 正確做法

```dart
// Controller 結構
class WorkoutController extends ChangeNotifier {
  final IWorkoutService _workoutService;
  List<WorkoutRecord> _records = [];
  
  List<WorkoutRecord> get records => _records;
  
  Future<void> loadRecords() async {
    _records = await _workoutService.getRecords();
    notifyListeners();  // 必須
  }
  
  void addRecord(WorkoutRecord record) {
    _records = [..._records, record];  // 重新賦值
    notifyListeners();
  }
}

// UI 使用
Consumer<WorkoutController>(
  builder: (context, controller, child) {
    return ListView.builder(
      itemCount: controller.records.length,
      itemBuilder: (context, index) => RecordCard(controller.records[index]),
    );
  },
)
```

## ❌ 禁止做法

```dart
// 忘記 notifyListeners
_data = newData;  // UI 不會更新

// 直接修改列表
_records.add(newRecord);  // 不會觸發更新

// build 中呼叫異步
Widget build(BuildContext context) {
  controller.loadData();  // 無限循環！
}
```

## 📦 GetIt 註冊

| 層級 | 方式 | 用途 |
|------|------|------|
| Service | `LazySingleton` | 全局共享 |
| Controller | `Factory` | 每次新實例 |


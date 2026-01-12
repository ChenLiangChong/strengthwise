---
description: "Flutter/Dart 編碼標準、命名規範與型別安全規則。適用於所有 Dart 檔案。"
globs: **/*.dart
alwaysApply: false
---

# Flutter/Dart 編碼標準

<critical>
1. 禁止使用 `dynamic`（除非絕對必要）
2. 禁止使用 `print()`，必須使用 `debugPrint()` 或 Logger
3. 禁止跨層 Relative Import，必須使用 `package:strengthwise/...`
4. 禁止強制解包 `!`，必須使用 `?` 和 `??`
5. 禁止直接操作 `Map<String, dynamic>`，必須透過 Model
</critical>

## 🏷️ 命名規範

| 類型 | 方式 | 範例 |
|------|------|------|
| Classes | PascalCase | `WorkoutController` |
| Variables | camelCase | `isLoading` |
| Files | snake_case | `user_model.dart` |
| Private | _prefix | `_userId` |

## ✅ 正確做法

```dart
// 型別安全
final record = WorkoutRecord.fromSupabase(data);

// 空安全
final name = user?.displayName ?? '未命名';

// Dart Doc 註解（繁體中文）
/// 建立新的訓練模板
Future<String> createTemplate(WorkoutTemplate template) async {}

// const 優化
const SizedBox(height: 16),

// async/await
final data = await fetchData();
```

## ❌ 禁止做法

```dart
// 強制解包
final name = user!.displayName;

// 直接 Map
await supabase.from('users').insert({'name': 'Test'});

// .then 鏈式
fetchData().then((data) => process(data));
```

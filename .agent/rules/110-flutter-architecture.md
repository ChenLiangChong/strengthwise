---
description: "Clean Architecture 分層規則、依賴注入與目錄結構強制執行。適用於 lib/ 下所有檔案。"
globs: lib/**/*.dart
alwaysApply: false
---

# Flutter 架構規範

<critical>
1. 禁止直接實例化 Service，必須透過 `serviceLocator<Interface>`
2. 禁止跨層依賴（View 不能直接呼叫 Service）
3. Controller 必須繼承 `ChangeNotifier`
4. Model 必須實作 `fromSupabase()` 和 `toMap()`
</critical>

## 🏗️ 分層架構

```
View (lib/views/)
    ↓ Provider/Consumer
Controller (lib/controllers/)  ← ChangeNotifier
    ↓ Interface
Service (lib/services/)
    ↓
Model (lib/models/)  ← fromSupabase() / toMap()
```

## ✅ 正確做法

```dart
// 依賴注入
final workoutService = serviceLocator<IWorkoutService>();
final authController = serviceLocator<IAuthController>();
```

## ❌ 禁止做法

```dart
// 直接實例化
final service = WorkoutServiceSupabase();
```

## 📦 註冊方式

| 層級 | 方式 | 生命週期 |
|------|------|----------|
| Service | `LazySingleton` | 全局共享 |
| Controller | `Factory` | 每次新實例 |

## 🚀 新功能流程

```
Model → Interface → Service → 註冊 → Controller → UI → 測試
```

詳見：`@docs/PROJECT_OVERVIEW.md`


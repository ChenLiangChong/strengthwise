# FCM 推播通知完整配置 ⭐ v4.0

> Firebase Cloud Messaging (HTTP v1 API) + Supabase Edge Functions 配置指南

**建立日期**：2026-01-05  
**最後更新**：2026-02-10（v5.2 - Edge Function 安全加固）
**目標版本**：v4.0（跨用戶即時同步）

---

## 📚 相關架構文檔

> **⭐ 重要**：FCM 是 StrengthWise 三層同步架構的一部分。開發前請先閱讀：
> 
> **[SYNC_ARCHITECTURE_SPEC.md](planning/SYNC_ARCHITECTURE_SPEC.md)** - 完整同步架構規格
> 
> | 機制 | 用途 | 本文檔涵蓋 |
> |------|------|-----------|
> | EventBus | 個人本地同步 | ❌ |
> | Realtime | 跨用戶實時同步 | ❌ |
> | **FCM** | **跨用戶推播通知** | ✅ |

---

## 📋 架構總覽

```
┌──────────────┐     INSERT/UPDATE    ┌──────────────┐
│  Flutter App │ ───────────────────▶ │ appointments │
└──────────────┘                      └──────┬───────┘
       ▲                                     │
       │                                     │ Database Webhook
       │                                     ▼
       │                              ┌──────────────┐
       │                              │ Edge Function│
       │                              │ push-notify  │
       │                              └──────┬───────┘
       │                                     │
       │                                     │ HTTP v1 API
       │                                     ▼
       │                              ┌──────────────┐
       └──────────────────────────────│   FCM API    │
              FCM Push                └──────────────┘
```

---

## 步驟 0：Firebase 專案配置

### 0.1 確認 Android App 已創建

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 選擇專案：`strengthwise-91f02`
3. 確認「您的應用程式」區塊有 Android App（包名：`com.example.strengthwise`）
4. ✅ `google-services.json` 已放到 `android/app/`

### 0.2 確認 Gradle 配置

**android/build.gradle.kts（根目錄）：**

```kotlin
buildscript {
    dependencies {
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**android/app/build.gradle.kts：**

```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← FCM 必需
}
```

---

## 步驟 1：執行資料庫遷移

在 **Supabase Dashboard → SQL Editor** 執行：

```sql
-- 執行 Migration 033: 用戶設備表
-- 完整內容見 migrations/033_user_devices.sql
```

**創建的資源**：
- `user_devices` 表（用戶 ID、FCM Token、平台、設備名稱）
- `upsert_device_token()` RPC 函數
- `remove_device_token()` RPC 函數
- `remove_invalid_tokens()` RPC 函數
- `get_user_tokens()` RPC 函數

---

## 步驟 2：設置 Supabase Secrets

在終端機執行（需要 Supabase CLI）：

```bash
# 進入專案目錄
cd D:\gitDir\strengthwise-dev

# 設置 FCM HTTP v1 API 憑證（從 Service Account JSON 獲取）
supabase secrets set FCM_PROJECT_ID=strengthwise-91f02
supabase secrets set FCM_CLIENT_EMAIL=firebase-adminsdk-fbsvc@strengthwise-91f02.iam.gserviceaccount.com
supabase secrets set FCM_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...你的私鑰...\n-----END PRIVATE KEY-----\n"
```

**⚠️ 重要**：
- `FCM_PRIVATE_KEY` 中的換行要保留為 `\n`
- 整個值用雙引號包裹
- 不要洩露這些資訊！

---

## 步驟 3：部署 Edge Functions

```bash
# 進入 supabase 目錄
cd supabase

# 部署三個 Edge Functions
supabase functions deploy push-notify
supabase functions deploy session-reminder
supabase functions deploy readiness-notify

# 驗證部署
supabase functions list
```

---

## 步驟 4：配置 Database Webhooks

在 **Supabase Dashboard → Database → Webhooks** 創建：

### Webhook 1：預約通知

| 欄位 | 值 |
|------|-----|
| **名稱** | `push_notify_appointments` |
| **表** | `appointments` |
| **事件** | ✅ INSERT, ✅ UPDATE |
| **HTTP 方法** | POST |
| **URL** | `https://你的專案ID.supabase.co/functions/v1/push-notify` |

**Headers：**
```json
{
  "Authorization": "Bearer 你的SERVICE_ROLE_KEY",
  "Content-Type": "application/json"
}
```

### Webhook 2：問卷通知

| 欄位 | 值 |
|------|-----|
| **名稱** | `readiness_notify` |
| **表** | `daily_readiness` |
| **事件** | ✅ UPDATE |
| **HTTP 方法** | POST |
| **URL** | `https://你的專案ID.supabase.co/functions/v1/readiness-notify` |

**Headers：**（同上）

### Webhook 3：教練時段通知 ⭐ v3.9

| 欄位 | 值 |
|------|-----|
| **名稱** | `push_notify_availability_slots` |
| **表** | `availability_slots` |
| **事件** | ✅ INSERT, ✅ UPDATE |
| **HTTP 方法** | POST |
| **URL** | `https://你的專案ID.supabase.co/functions/v1/push-notify` |

**Headers：**（同上）

### Webhook 4：學員可訓練時間通知 ⭐ v3.9

| 欄位 | 值 |
|------|-----|
| **名稱** | `push_notify_client_availability` |
| **表** | `client_availability` |
| **事件** | ✅ INSERT, ✅ UPDATE |
| **HTTP 方法** | POST |
| **URL** | `https://你的專案ID.supabase.co/functions/v1/push-notify` |

**Headers：**（同上）

### Webhook 5：訓練計畫通知 ⭐ v3.9

| 欄位 | 值 |
|------|-----|
| **名稱** | `push_notify_workout_plans` |
| **表** | `workout_plans` |
| **事件** | ✅ INSERT, ✅ DELETE |
| **HTTP 方法** | POST |
| **URL** | `https://你的專案ID.supabase.co/functions/v1/push-notify` |

**Headers：**（同上）

> **注意**：workout_plans 不需要 UPDATE 事件（只通知新增和刪除）

---

## 步驟 5：設置定時任務（pg_cron）

在 **SQL Editor** 執行：

```sql
-- 啟用必要擴展
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 創建定時任務（每 5 分鐘）
SELECT cron.schedule(
  'session-reminder-job',
  '*/5 * * * *',
  $$
  SELECT net.http_post(
    url := 'https://你的專案ID.supabase.co/functions/v1/session-reminder',
    headers := jsonb_build_object(
      'Authorization', 'Bearer 你的SERVICE_ROLE_KEY',
      'Content-Type', 'application/json'
    ),
    body := '{}'::jsonb
  );
  $$
);

-- 驗證
SELECT * FROM cron.job;
```

---

## 步驟 6：測試

### 測試 Edge Function

```bash
curl -X POST \
  "https://你的專案ID.supabase.co/functions/v1/push-notify" \
  -H "Authorization: Bearer 你的ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "INSERT",
    "table": "appointments",
    "record": {
      "id": "test-id",
      "status": "requested",
      "coach_id": "教練UUID",
      "client_id": "學員UUID",
      "time_range": "[\"2026-01-05T10:00:00+08:00\",\"2026-01-05T11:00:00+08:00\")"
    }
  }'
```

---

## 🔑 如何找到這些值

| 值 | 位置 |
|----|------|
| **專案 ID** | Supabase Dashboard → Settings → General → Reference ID |
| **ANON_KEY** | Settings → API → anon public |
| **SERVICE_ROLE_KEY** | Settings → API → service_role（⚠️ 不要洩露！）|

---

## ✅ 完成檢查清單

### 後端配置 ✅ 2026-01-17 更新

- [x] `google-services.json` 已放到 `android/app/`
- [x] Android Gradle 配置已更新
- [x] Migration 033 執行成功（`user_devices` 表）
- [x] Supabase Secrets 已設置（FCM_PROJECT_ID, FCM_CLIENT_EMAIL, FCM_PRIVATE_KEY）
- [x] Edge Functions 部署成功（push-notify, session-reminder, readiness-notify）
- [x] Webhooks 已創建：
  - [x] `push_notify_appointments`（預約通知）
  - [x] `readiness_notify`（問卷通知）
  - [x] `push_notify_availability_slots`（教練時段通知）⭐ v3.9
  - [x] `push_notify_client_availability`（學員可訓練時間通知）⭐ v3.9
  - [x] `push_notify_workout_plans`（訓練計畫通知）⭐ v3.9
- [x] pg_cron 定時任務已創建（每 5 分鐘執行）
- [x] NotificationRouter 導航已實現 ⭐ v3.9

### App 端測試 ✅ v3.9

- [x] 登入時 Token 保存到 `user_devices`
- [x] 預約狀態變更收到推播
- [x] 課前 1hr 收到提醒
- [x] 點擊通知跳轉正確（首頁/行事曆/教練中心/學員中心）

---

## 🐛 常見問題

### Q: Edge Function 返回 500

檢查 Supabase Dashboard → Edge Functions → Logs

常見原因：
- FCM Secrets 未設置
- `FCM_PRIVATE_KEY` 格式錯誤（換行問題）

### Q: 收不到通知

1. 檢查 `user_devices` 表是否有 Token
2. 檢查 App 是否正確調用 `saveTokenToDatabase()`
3. 檢查 Edge Function Logs

### Q: pg_cron 不執行

```sql
-- 確認擴展已啟用
SELECT * FROM pg_extension WHERE extname IN ('pg_cron', 'pg_net');

-- 確認任務存在
SELECT * FROM cron.job;
```

---

## 📱 Flutter 端配置

### 初始化通知服務

在 `main.dart` 中：

```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化 Firebase
  await Firebase.initializeApp();
  
  // 初始化推播服務
  final notificationService = serviceLocator<INotificationService>();
  await notificationService.initialize();
  
  runApp(const MyApp());
}
```

### 登入後保存 Token

```dart
final token = await notificationService.getToken();
if (token != null) {
  await notificationService.saveTokenToDatabase(
    userId, 
    token,
    platform: Platform.isAndroid ? 'android' : 'ios',
  );
  notificationService.listenForTokenChanges(userId);
}
```

### 登出時移除 Token

```dart
await notificationService.removeTokenFromDatabase(userId);
```

---

## 🔐 Edge Function 安全配置（v5.2）

v5.2 安全加固對三個 Edge Function 進行了以下安全改善：

### CORS 配置

```
變更前：Access-Control-Allow-Origin: *
變更後：移除 CORS headers（不需要）
```

**原因**：Edge Function 僅由 Database Webhook 和 pg_cron 內部調用，不經過瀏覽器，不需要 CORS。

### HSTS Header

所有回應新增：
```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```

### 錯誤回應

```
變更前：回傳詳細錯誤訊息（可能洩漏內部實作）
變更後：統一回傳 "Internal server error"
```

### 日誌精簡

```
變更前：console.log 輸出完整 payload（含用戶資料）
變更後：僅記錄必要資訊（表名、事件類型），移除敏感資料
```

### 受影響的函式

| 函式 | 修改內容 |
|------|----------|
| `push-notify/index.ts` | CORS 移除 + HSTS + 錯誤隱藏 + 日誌精簡 |
| `session-reminder/index.ts` | CORS 移除 + HSTS + 錯誤隱藏 + 日誌精簡 |
| `readiness-notify/index.ts` | CORS 移除 + HSTS + 錯誤隱藏 + 日誌精簡 |

---

## 📎 相關文件

### 架構文檔

| 文件 | 說明 |
|------|------|
| `docs/planning/SYNC_ARCHITECTURE_SPEC.md` | **同步架構規格**（EventBus/Realtime/FCM 決策）⭐ v4.0 |

### Flutter 端

| 文件 | 說明 |
|------|------|
| `lib/services/interfaces/i_notification_service.dart` | 服務接口 |
| `lib/services/notification/notification_service.dart` | 服務實作 |
| `lib/services/notification/notification_router.dart` | 通知點擊導航 ⭐ v3.9 |

### Edge Functions

| 文件 | 說明 |
|------|------|
| `supabase/functions/_shared/fcm.ts` | FCM HTTP v1 API 共用模組 |
| `supabase/functions/_shared/notification_types.ts` | 通知類型定義 ⭐ v3.9 |
| `supabase/functions/push-notify/index.ts` | 預約/時段/訓練通知 Edge Function |
| `supabase/functions/session-reminder/index.ts` | 課前提醒 Edge Function |
| `supabase/functions/readiness-notify/index.ts` | 問卷通知 Edge Function |

### 資料庫

| 文件 | 說明 |
|------|------|
| `migrations/033_user_devices.sql` | 用戶設備表遷移 |
| `migrations/33_enable_realtime_availability.sql` | Realtime 配置 ⭐ v3.9 |

---

## 📊 HTTP v1 API vs Legacy API

| 項目 | Legacy API | HTTP v1 API ✅ |
|------|-----------|---------------|
| 認證方式 | Server Key | OAuth 2.0 JWT |
| 安全性 | 較低（Key 易洩露）| 高（短期 Token）|
| 功能 | 基本 | 完整（APNs 整合）|
| 未來支援 | 已棄用 | 長期支援 |

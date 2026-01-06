# FCM 推播通知完整配置 ⭐ v3.0-C

> Firebase Cloud Messaging + Supabase Edge Functions 配置指南

**建立日期**：2026-01-05  
**目標版本**：v3.0-C（即時通訊）

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
       │                                     │ HTTP POST
       │                                     ▼
       │                              ┌──────────────┐
       └──────────────────────────────│   FCM API    │
              FCM Push                └──────────────┘
```

---

## 步驟 0：Firebase 專案配置（如需啟用推播）

### 0.1 創建 Firebase 專案

1. 前往 [Firebase Console](https://console.firebase.google.com/)
2. 創建新專案或選擇現有專案
3. 添加 Android App（包名：`com.example.strengthwise`）
4. 下載 `google-services.json` → 放到 `android/app/`

### 0.2 更新 Android 配置

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
    id("com.google.gms.google-services")  // ← 添加這行
}
```

---

## 步驟 1：執行資料庫遷移

在 **Supabase Dashboard → SQL Editor** 執行：

```sql
-- ============================================================
-- Migration 032: 用戶 FCM Token 欄位
-- ============================================================

-- 1. 添加 fcm_tokens 欄位
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS fcm_tokens TEXT[] DEFAULT '{}';

COMMENT ON COLUMN public.users.fcm_tokens IS 'FCM 推播 Token 陣列（支援多設備登入）';

-- 2. 創建 RPC 函數：安全地 upsert FCM Token
CREATE OR REPLACE FUNCTION public.upsert_fcm_token(
  p_user_id UUID,
  p_token TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users
  SET 
    fcm_tokens = ARRAY(
      SELECT DISTINCT unnest(
        CASE 
          WHEN fcm_tokens IS NULL THEN ARRAY[p_token]
          WHEN p_token = ANY(fcm_tokens) THEN fcm_tokens
          ELSE fcm_tokens || p_token
        END
      )
    ),
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$;

-- 3. 創建 RPC 函數：移除 FCM Token
CREATE OR REPLACE FUNCTION public.remove_fcm_token(
  p_user_id UUID,
  p_token TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.users
  SET 
    fcm_tokens = ARRAY(
      SELECT unnest(fcm_tokens)
      EXCEPT
      SELECT p_token
    ),
    updated_at = NOW()
  WHERE id = p_user_id;
END;
$$;

-- 4. 創建索引
CREATE INDEX IF NOT EXISTS idx_users_fcm_tokens 
ON public.users USING GIN (fcm_tokens);

-- 驗證
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'fcm_tokens';
```

---

## 步驟 2：設置 Secrets

在終端機執行（需要 Supabase CLI）：

```bash
# 替換為你的 FCM Server Key
supabase secrets set FCM_SERVER_KEY=AAAAxxxxxxx:APA91bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

**如何獲取 FCM Server Key：**
1. Firebase Console → 專案設置 → Cloud Messaging
2. 找到「Server key」或「Cloud Messaging API (Legacy)」
3. 如果沒有，點擊「管理 API」啟用

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

---

## 步驟 5：設置定時任務（pg_cron）

在 **SQL Editor** 執行：

```sql
-- ============================================================
-- 課前提醒定時任務（每 5 分鐘）
-- ============================================================

-- 1. 啟用 pg_cron 擴展（如果尚未啟用）
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- 2. 啟用 pg_net 擴展（HTTP 請求）
CREATE EXTENSION IF NOT EXISTS pg_net;

-- 3. 創建定時任務
SELECT cron.schedule(
  'session-reminder-job',           -- 任務名稱
  '*/5 * * * *',                    -- 每 5 分鐘
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

-- 4. 驗證任務已創建
SELECT * FROM cron.job;

-- 5. 查看執行歷史（執行後）
SELECT * FROM cron.job_run_details ORDER BY start_time DESC LIMIT 10;
```

**⚠️ 注意：** 將 `你的專案ID` 和 `你的SERVICE_ROLE_KEY` 替換為實際值。

---

## 步驟 6：測試

### 測試 Edge Function

```bash
# 測試 push-notify
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

### 測試定時任務

```sql
-- 手動觸發一次
SELECT net.http_post(
  url := 'https://你的專案ID.supabase.co/functions/v1/session-reminder',
  headers := jsonb_build_object(
    'Authorization', 'Bearer 你的SERVICE_ROLE_KEY',
    'Content-Type', 'application/json'
  ),
  body := '{}'::jsonb
);

-- 查看結果
SELECT * FROM net._http_response ORDER BY created DESC LIMIT 5;
```

---

## 🔑 如何找到這些值

| 值 | 位置 |
|----|------|
| **專案 ID** | Supabase Dashboard → Settings → General → Reference ID |
| **ANON_KEY** | Settings → API → anon public |
| **SERVICE_ROLE_KEY** | Settings → API → service_role（⚠️ 不要洩露！）|
| **FCM_SERVER_KEY** | Firebase Console → 專案設置 → Cloud Messaging |

---

## ✅ 完成檢查清單

- [x] Migration 032 執行成功（users 表有 fcm_tokens 欄位）
- [ ] FCM_SERVER_KEY 已設置（需 Firebase 專案）
- [x] push-notify 部署成功
- [x] session-reminder 部署成功
- [x] readiness-notify 部署成功
- [x] Webhook `push_notify_appointments` 已創建
- [x] Webhook `readiness_notify` 已創建
- [x] pg_cron 定時任務已創建
- [ ] 測試 curl 請求成功（需 FCM_SERVER_KEY）

---

## 🐛 常見問題

### Q: Edge Function 返回 500

檢查 Supabase Dashboard → Edge Functions → Logs

### Q: 收不到通知

1. 檢查 `fcm_tokens` 欄位是否有值
2. 檢查 FCM_SERVER_KEY 是否正確
3. 檢查 App 是否正確保存了 Token

### Q: pg_cron 不執行

```sql
-- 確認擴展已啟用
SELECT * FROM pg_extension WHERE extname IN ('pg_cron', 'pg_net');

-- 確認任務存在
SELECT * FROM cron.job;
```

---

## 📱 Flutter 端配置（如需啟用推播）

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
  await notificationService.saveTokenToDatabase(userId, token);
  notificationService.listenForTokenChanges(userId);
}
```

### 登出時移除 Token

```dart
await notificationService.removeTokenFromDatabase(userId);
```

---

## 📎 相關文件

| 文件 | 說明 |
|------|------|
| `lib/services/interfaces/i_notification_service.dart` | 服務接口 |
| `lib/services/notification/notification_service.dart` | 服務實作 |
| `supabase/functions/push-notify/index.ts` | 預約通知 Edge Function |
| `supabase/functions/session-reminder/index.ts` | 課前提醒 Edge Function |
| `supabase/functions/readiness-notify/index.ts` | 問卷通知 Edge Function |
| `migrations/032_users_fcm_tokens.sql` | 資料庫遷移 |

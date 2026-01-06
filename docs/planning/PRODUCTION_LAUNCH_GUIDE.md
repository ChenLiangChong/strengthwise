# 構建高可靠性 Flutter、Supabase 與 FCM 生產環境

> 架構驗證與發布策略綜合報告

**最後更新**：2026-01-07  
**目標版本**：v3.1-A  
**適用範圍**：Google Play 上架準備

---

## 📋 目錄

1. [執行摘要與架構戰略](#1-執行摘要與架構戰略)
2. [數據庫安全性架構與行級防禦](#2-數據庫安全性架構與行級防禦)
3. [無伺服器架構與 FCM 通知編排](#3-無伺服器架構與-fcm-通知編排)
4. [Flutter 客戶端集成與原生權限管理](#4-flutter-客戶端集成與原生權限管理)
5. [全方位測試策略](#5-全方位測試策略)
6. [部署管道與基礎設施管理](#6-部署管道與基礎設施管理)
7. [合規性與商店政策 (2025 標準)](#7-合規性與商店政策-2025-標準)
8. [生產發布檢查清單](#8-生產發布檢查清單)
9. [附錄：關鍵數據與配置參考](#9-附錄關鍵數據與配置參考)

---

## 1. 執行摘要與架構戰略

在現代移動應用開發的生態系統中，將 Flutter 的跨平台能力與 Supabase 的後端即服務（BaaS）架構以及 Firebase Cloud Messaging（FCM）的推送通知服務相結合，已成為構建可擴展、即時互動應用的主流方案。

### 核心挑戰

從原型開發過渡到生產環境（Production Launch）的過程中，開發團隊面臨著極具挑戰性的技術門檻：

- **RLS 安全性**：數據庫行級安全性的嚴格執行
- **Edge Functions 優化**：無伺服器邊緣計算的冷啟動優化
- **FCM 認證遷移**：HTTP v1 API 的 OAuth 2.0 認證
- **隱私權限管控**：Android 13+ 與 iOS 對隱私權限的嚴格管控

---

## 2. 數據庫安全性架構與行級防禦

生產環境的安全性並非附加功能，而是數據庫架構的核心組成部分。

### 2.1 行級安全性 (RLS) 的深度實施

> ⚠️ **重要**：任何依賴客戶端過濾數據的行為都被視為嚴重安全漏洞

#### 策略設計模式

| 策略類型 | 實施機制 | 安全性評級 | 性能影響 | 適用場景 |
|---------|---------|-----------|---------|---------|
| 用戶隔離 | `auth.uid() = user_id` | 高 | 低 | 私人數據（如訓練記錄）|
| 團隊/租戶隔離 | `EXISTS (SELECT 1 FROM members WHERE...)` | 中 | 高 (涉及 JOIN) | 教練學員系統 |
| 公開只讀 | `true` (針對 SELECT) | 低 (公開) | 極低 | 動作資料庫 |
| 基於 Claims | `(auth.jwt() ->> 'role') = 'admin'` | 高 | 低 | 管理員權限控制 |

#### RLS 的性能陷阱與優化

```sql
-- ✅ 為 RLS 策略中涉及的列建立索引
CREATE INDEX idx_workout_records_user_id ON workout_records(user_id);
CREATE INDEX idx_coaching_relationships_coach_id ON coaching_relationships(coach_id);

-- 使用 EXPLAIN ANALYZE 驗證查詢成本
EXPLAIN ANALYZE SELECT * FROM workout_records WHERE user_id = 'xxx';
```

### 2.2 API 金鑰管理

| 金鑰類型 | 用途 | 安全等級 | 存放位置 |
|---------|------|---------|---------|
| `anon` | 客戶端公開使用 | 低風險 | Flutter 代碼 |
| `service_role` | 繞過 RLS | **上帝權限** | 僅限 Edge Functions |

<critical>
❌ **絕對禁止**：將 service_role 金鑰硬編碼在 Flutter 客戶端代碼中
</critical>

---

## 3. 無伺服器架構與 FCM 通知編排

### 3.1 HTTP v1 API 遷移

Google 已全面棄用舊版 FCM API，強制使用 HTTP v1 API（OAuth 2.0 認證）。

#### Deno 運行時解決方案

```typescript
// 使用 Deno 兼容的 JWT 庫
import { create, getNumericDate } from "https://deno.land/x/djwt@v2.8/mod.ts";

async function getAccessToken(serviceAccount: any) {
  const jwt = await create(
    { alg: "RS256", typ: "JWT" },
    {
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: getNumericDate(0),
      exp: getNumericDate(3600),
    },
    { key: serviceAccount.private_key }
  );
  // ... 交換 Access Token
}
```

### 3.2 觸發機制選擇

| 特性 | Database Webhooks | PostgreSQL Triggers (pg_net) |
|-----|-------------------|------------------------------|
| 執行模式 | 異步 | 可同步或異步 |
| 事務影響 | 失敗不回滾 | 失敗可能回滾 |
| 重試機制 | 內建指數退避 | 需手動實現 |
| **生產推薦** | ✅ | ❌ |

### 3.3 錯誤處理與 Token 清理

```typescript
// 當 FCM 返回 UNREGISTERED 時，自動刪除無效 Token
if (responseData.error?.details?.errorCode === 'UNREGISTERED') {
  await supabaseAdmin
    .from('user_devices')
    .delete()
    .eq('fcm_token', device.fcm_token);
}
```

---

## 4. Flutter 客戶端集成與原生權限管理

### 4.1 Android 13+ 權限策略

自 Android 13 起，`POST_NOTIFICATIONS` 需要運行時請求。

#### 請求時機最佳實踐

| 時機 | 授權率 | 建議 |
|-----|-------|-----|
| 首次啟動 | 低 | ❌ 避免 |
| 完成關鍵操作後 | 高 | ✅ 推薦 |
| 用戶主動觸發 | 極高 | ✅ 最佳 |

```dart
// ✅ 在用戶完成預約後請求權限
Future<void> onBookingConfirmed() async {
  // 先完成預約邏輯
  await _bookingService.confirm(appointment);
  
  // 然後請求通知權限（上下文關聯）
  final status = await Permission.notification.request();
  if (status.isDenied) {
    _showPermissionGuide(); // 引導用戶到設置頁面
  }
}
```

### 4.2 FCM Token 生命週期管理

```dart
class TokenManager {
  /// 初始化同步
  Future<void> syncToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _upsertToken(token);
    }
  }
  
  /// 監聽變更
  void listenForRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen(_upsertToken);
  }
  
  /// Upsert 到數據庫
  Future<void> _upsertToken(String token) async {
    await supabase.from('user_devices').upsert({
      'user_id': supabase.auth.currentUser!.id,
      'fcm_token': token,
      'device_type': Platform.isAndroid ? 'android' : 'ios',
      'last_updated': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,fcm_token');
  }
}
```

### 4.3 深度鏈接與狀態恢復

| 應用狀態 | 處理方式 | 關鍵 API |
|---------|---------|---------|
| 前台 | 應用內 Snackbar | `onMessage` |
| 後台 | 喚醒並跳轉 | `onMessageOpenedApp` |
| 終止 | 冷啟動後跳轉 | `getInitialMessage()` |

---

## 5. 全方位測試策略

### 5.1 測試金字塔

```
        /\
       /  \     E2E (Patrol)
      /----\    原生權限 + 通知驗證
     /      \
    /--------\  Integration
   /          \ Flutter + Supabase 協同
  /------------\
 /              \ Unit Tests
/----------------\ 純 Dart 邏輯 + Mock
```

### 5.2 Patrol 自動化測試

傳統 `integration_test` 無法與原生 UI 交互。Patrol 解決了這一痛點：

```dart
// 自動處理權限彈窗
await $.native.grantPermissionWhenInUse();

// 驗證通知欄內容
await $.native.openNotifications();
await $.native.tapOnNotificationBySelector(
  Selector(textContains: '新課程預約'),
);
```

### 5.3 測試框架功能對比

| 功能特性 | flutter_test | integration_test | Patrol |
|---------|-------------|-----------------|--------|
| 測試範圍 | 純 Dart 邏輯 | Flutter Widget | Flutter + Native UI |
| 通知欄交互 | ❌ | ❌ | ✅ |
| 權限彈窗交互 | ❌ | ❌ | ✅ |
| 設備農場集成 | ❌ | ✅ | ✅ |

---

## 6. 部署管道與基礎設施管理

### 6.1 環境隔離

```
開發 (Dev)          預備 (Staging)       生產 (Prod)
    │                    │                   │
    ▼                    ▼                   ▼
supabase-dev        supabase-staging    supabase-prod
    │                    │                   │
    └────────────────────┴───────────────────┘
                         │
                   Git 版本控制
                   (migrations/)
```

### 6.2 數據庫遷移流程

```bash
# 創建遷移
supabase migration new add_user_devices_table

# 本地測試
supabase db reset

# 推送到生產（CI/CD 自動執行）
supabase db push --linked
```

---

## 7. 合規性與商店政策 (2025 標準)

### 7.1 Google Play 數據安全申報

| 數據類型 | 收集 | 用途 | 共享 |
|---------|-----|------|-----|
| 設備 ID | ✅ | 推播通知 | Firebase |
| 用戶 Email | ✅ | 帳號認證 | Supabase |
| 健康數據 | ✅ | 應用功能 | ❌ |

### 7.2 高敏感權限審核

| 權限 | Google Play 態度 | 建議替代方案 |
|-----|-----------------|-------------|
| `EXACT_ALARM` | 嚴格審核 | 使用 FCM 推送 |
| `BACKGROUND_LOCATION` | 需詳細說明 | 僅前台定位 |
| Health Connect | 必須申報 | 完成健康應用聲明 |

---

## 8. 生產發布檢查清單

### 8.1 數據庫與安全性

```
□ RLS 全覆蓋驗證：public schema 所有表均已啟用
□ 匿名訪問審計：檢查 anon 角色的寫入權限
□ 索引優化：RLS 策略中的外鍵列已建立索引
□ 金鑰掃描：確保 service_role 未提交到 Git
□ 備份策略：啟用 PITR 並測試過恢復流程
```

### 8.2 後端邏輯與通知

```
□ FCM 認證：Edge Function 正確生成 OAuth2 Token
□ Webhook 觸發：高負載下不阻塞數據庫寫入
□ 無效 Token 清理：FCM 錯誤時自動刪除
□ 密鑰輪換：生產環境使用獨立的 Service Account
```

### 8.3 客戶端 (Flutter)

```
□ 權限流程：Android 13+ 真機測試權限請求
□ 冷啟動跳轉：終止狀態點擊通知能正確跳轉
□ Token 同步：弱網環境下的可靠性
□ 代碼混淆：Release 包已啟用 Obfuscation
```

### 8.4 合規與運維

```
□ 環境變量：CI/CD 生產配置正確
□ 隱私政策：數據安全表單已更新
□ 監控告警：Edge Function 錯誤率告警已配置
```

---

## 9. 附錄：關鍵數據與配置參考

### 9.1 設備 Token 數據庫設計

```sql
-- 表結構：存儲用戶設備與 FCM Token
CREATE TABLE public.user_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    fcm_token TEXT NOT NULL,
    device_type TEXT CHECK (device_type IN ('android', 'ios', 'web')),
    app_version TEXT,
    last_updated TIMESTAMPTZ DEFAULT now(),
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE(user_id, fcm_token)
);

-- 索引
CREATE INDEX idx_user_devices_user_id ON public.user_devices(user_id);
CREATE INDEX idx_user_devices_last_updated ON public.user_devices(last_updated);

-- RLS
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own devices" ON public.user_devices
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can register devices" ON public.user_devices
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own devices" ON public.user_devices
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own devices" ON public.user_devices
    FOR DELETE USING (auth.uid() = user_id);
```

### 9.2 Edge Function 完整範例

詳見 `supabase/functions/push-notify/index.ts`

---

## 相關文檔

- [TESTING_STRATEGY.md](./TESTING_STRATEGY.md) - 詳細測試清單
- [FCM_SETUP_GUIDE.md](../FCM_SETUP_GUIDE.md) - FCM 配置指南
- [DATABASE_SUPABASE.md](../DATABASE_SUPABASE.md) - 數據庫 Schema
- [DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md) - 部署流程


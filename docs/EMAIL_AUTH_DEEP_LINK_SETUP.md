# Email Authentication Deep Link 配置指南

> 完整設定 Supabase Email 確認連結的 Deep Link 處理

**最後更新**：2026年1月2日

---

## 📋 已完成的配置

### 1️⃣ **Flutter 端配置** ✅

- ✅ 添加 `app_links` 依賴
- ✅ 配置 Android Deep Link（`AndroidManifest.xml`）
- ✅ 創建 `DeepLinkService`（處理 Email 確認連結）
- ✅ 在 `main.dart` 初始化 Deep Link 服務

### 2️⃣ **Android 配置** ✅

**AndroidManifest.xml**:
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="com.example.strengthwise"
        android:host="login-callback" />
</intent-filter>
```

---

## 🚀 待完成配置（Supabase Dashboard）

### 3️⃣ **Supabase Redirect URLs 配置** ⚠️

1. 進入 Supabase Dashboard
2. 進入專案設定：**Authentication** → **URL Configuration**
3. 在 **Redirect URLs** 添加：
   ```
   com.example.strengthwise://login-callback
   ```
4. 在 **Site URL** 設定（可選）：
   ```
   com.example.strengthwise://
   ```
5. **儲存變更**

### 4️⃣ **Email Templates 配置**（可選優化）

1. 進入 **Authentication** → **Email Templates**
2. 編輯 **Confirm signup** 模板
3. 確認 `{{ .ConfirmationURL }}` 會使用 Redirect URL

---

## 🧪 測試步驟

### 測試流程：

1. **註冊新帳號**：
   ```dart
   await authService.signUpWithEmail(
     email: 'test@example.com',
     password: 'password123',
   );
   ```

2. **檢查郵件**：
   - 收到確認郵件
   - 確認連結格式應該是：`com.example.strengthwise://login-callback#access_token=...`

3. **點擊確認連結**：
   - App 自動開啟
   - Deep Link Service 處理認證
   - 用戶自動登入 ✅

### 驗證日誌：

```
[DEEP_LINK_SERVICE] 收到 Deep Link: com.example.strengthwise://login-callback#access_token=...
[DEEP_LINK_SERVICE] ✅ Email 確認成功，處理認證
[AUTH_SUPABASE] 用戶已登入: test@example.com
```

---

## 🐛 常見問題

### 問題 1：點擊連結還是跳到 localhost

**原因**：Supabase Dashboard 未配置 Redirect URL

**解決**：完成「步驟 3️⃣」的 Supabase 配置

### 問題 2：App 無法開啟

**原因**：Android Deep Link 配置錯誤

**檢查**：
```bash
# 驗證 Deep Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.example.strengthwise://login-callback#test=123" \
  com.example.strengthwise
```

### 問題 3：確認後無法登入

**原因**：Supabase PKCE 流程配置

**檢查**：
- `SupabaseService` 已配置 `authFlowType: AuthFlowType.pkce` ✅
- Supabase Dashboard 啟用了 PKCE

---

## 📱 多平台支援

### iOS 配置（未來）

**Info.plist**:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.example.strengthwise</string>
    </array>
  </dict>
</array>
```

### Web 配置（未來）

**Redirect URL**:
```
https://yourdomain.com/auth/callback
```

---

## 🔒 安全性考量

1. **Scheme 唯一性**：
   - 使用 `com.example.strengthwise` 而非 `strengthwise`
   - 避免與其他 App 衝突

2. **PKCE 流程**：
   - ✅ 已啟用 `AuthFlowType.pkce`
   - 防止授權碼攔截攻擊

3. **Token 處理**：
   - Supabase SDK 自動處理 Token
   - 不需要手動儲存 Access Token

---

## 📚 相關文檔

- [Supabase Auth Deep Links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Flutter app_links Package](https://pub.dev/packages/app_links)
- [Android App Links](https://developer.android.com/training/app-links)

---

**完成配置後，Email 註冊流程將完全正常工作！** ✅


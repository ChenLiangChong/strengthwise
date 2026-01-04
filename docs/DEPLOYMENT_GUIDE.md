# StrengthWise - 部署指南

> Release APK 構建、Google Sign-In 配置、發布流程完整指南

**最後更新**：2026年1月4日

---

## 📋 目錄

1. [Release APK 構建](#release-apk-構建)
2. [Google Sign-In 配置](#google-sign-in-配置)
3. [Email Authentication Deep Link 配置](#email-authentication-deep-link-配置)
4. [發布檢查清單](#發布檢查清單)
5. [版本管理](#版本管理)

---

## 🚀 Release APK 構建

### 快速構建流程

#### 方法 1：構建並自動安裝（推薦）

```bash
# 1. 確認手機已連接
adb devices

# 2. 構建 Release APK
flutter build apk --release

# 3. 安裝到手機
adb -s <DEVICE_ID> install -r build\app\outputs\flutter-apk\app-release.apk
```

#### 方法 2：只構建 APK

```bash
# 構建 Release APK
flutter build apk --release

# APK 位置：
# build\app\outputs\flutter-apk\app-release.apk
```

---

### 📦 APK 位置

構建成功後，APK 會生成在：
```
build\app\outputs\flutter-apk\app-release.apk
```

---

### 📱 安裝方法

#### 方法 1：通過 ADB 安裝（電腦連接手機）

```bash
# 替換為實際的設備 ID
adb -s <DEVICE_ID> install -r build\app\outputs\flutter-apk\app-release.apk
```

#### 方法 2：手動安裝（無需電腦）

1. 將 `app-release.apk` 複製到手機
2. 在手機上打開文件管理器
3. 點擊 APK 文件
4. 允許安裝未知來源應用（首次需要）
5. 點擊「安裝」

---

### 🔐 簽名 APK（正式發布時需要）

#### 創建簽名密鑰（只需做一次）

```bash
keytool -genkey -v -keystore ~/strengthwise-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias strengthwise
```

#### 配置簽名

1. **創建 `android/key.properties`**：
```properties
storePassword=你的密碼
keyPassword=你的密碼
keyAlias=strengthwise
storeFile=路徑/strengthwise-release-key.jks
```

2. **修改 `android/app/build.gradle.kts`**：
```kotlin
android {
    // ...
    signingConfigs {
        create("release") {
            val keystorePropertiesFile = rootProject.file("key.properties")
            val keystoreProperties = Properties()
            keystoreProperties.load(FileInputStream(keystorePropertiesFile))

            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

3. **構建簽名的 APK**：
```bash
flutter build apk --release
```

---

### 📊 構建選項

#### 構建單個 APK（通用）
```bash
flutter build apk --release
# 生成: app-release.apk (~55 MB)
```

#### 構建分架構 APK（更小）
```bash
flutter build apk --release --split-per-abi
# 生成:
# - app-armeabi-v7a-release.apk (~18 MB)
# - app-arm64-v8a-release.apk (~19 MB)
# - app-x86_64-release.apk (~20 MB)
```

#### 構建 AAB（Google Play 商店）
```bash
flutter build appbundle --release
# 生成: app-release.aab
```

---

### 🐛 常見問題

#### 1. 手機無法檢測到

```bash
# 重啟 ADB
adb kill-server
adb start-server
adb devices
```

#### 2. 安裝失敗

```bash
# 先卸載舊版本
adb -s <DEVICE_ID> uninstall com.example.strengthwise

# 重新安裝
adb -s <DEVICE_ID> install build\app\outputs\flutter-apk\app-release.apk
```

#### 3. 構建失敗

```bash
# 清理構建緩存
flutter clean
flutter pub get

# 重新構建
flutter build apk --release
```

---

## 🔐 Google Sign-In 配置

### 🎯 目標

讓你構建的 APK 在**任何手機**上都能正常使用 Google 登入。

---

### ✅ 必要步驟（完整流程）

#### 步驟 1：獲取 Release APK 的 SHA-1 指紋

##### 1.1 檢查當前使用的 Keystore

你的 Release APK 目前使用的是 **Debug Keystore**（因為沒有配置 Release Keystore）。

##### 1.2 獲取 Debug Keystore 的 SHA-1

**方法 1：通過 Gradle**

```bash
cd android
.\gradlew signingReport
```

在輸出中找到：
```
Variant: release
Config: debug
Store: C:\Users\<USERNAME>\.android\debug.keystore
Alias: androiddebugkey
SHA1: BB:81:9A:9F:7A:E1:E6:5F:D8:86:2E:FC:4D:8B:D0:94:E1:EA:70:69
```

**方法 2：直接使用 keytool**

打開**命令提示符**（不是 PowerShell）：

```cmd
cd /d "%USERPROFILE%\.android"
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr SHA1
```

**方法 3：使用 Android Studio 的 keytool**

```cmd
cd /d "C:\Program Files\Android\Android Studio\jbr\bin"
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | findstr SHA1
```

---

#### 步驟 2：在 Google Cloud Console 新增 SHA-1

1. 開啟 [Google Cloud Console](https://console.cloud.google.com/)
2. 選擇你的專案（StrengthWise）
3. 左側選單 → **APIs & Services** → **Credentials**
4. 找到你的 **OAuth 2.0 Client ID**（類型：Android）
5. 點擊編輯（鉛筆圖標）
6. 在「**SHA-1 certificate fingerprints**」區域：
   - 點擊「**+ Add fingerprint**」
   - 貼上你的 Debug Keystore SHA-1
   - 點擊「**Save**」

---

#### 步驟 3：在 Supabase 更新 Google Provider 配置

1. 開啟 [Supabase Dashboard](https://app.supabase.com/)
2. 選擇你的專案
3. 左側選單 → **Authentication** → **Providers**
4. 找到「**Google**」→ 點擊展開
5. 確認以下設定：
   - **Enabled**: ✅ 開啟
   - **Client ID**: 你的 Google OAuth Client ID
   - **Client Secret**: 你的 Google OAuth Client Secret
   - **Authorized Client IDs**: 新增你的 Android OAuth Client ID

---

#### 步驟 4：測試 Google 登入

1. 構建 Release APK：
   ```bash
   flutter build apk --release
   ```

2. 安裝到測試手機：
   ```bash
   adb -s <DEVICE_ID> install -r build\app\outputs\flutter-apk\app-release.apk
   ```

3. 在測試手機上：
   - 開啟 StrengthWise
   - 點擊「Google 登入」
   - 選擇 Google 帳號
   - 確認權限
   - 成功登入 ✅

---

### 🔧 進階配置

#### 創建 Release Keystore（建議）

如果你要正式發布到 Google Play，建議創建專用的 Release Keystore：

```bash
keytool -genkey -v -keystore ~/strengthwise-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias strengthwise
```

然後：
1. 獲取 Release Keystore 的 SHA-1
2. 在 Google Cloud Console 新增這個 SHA-1
3. 配置 `android/key.properties`（參考上方「簽名 APK」章節）

---

### 🐛 Google Sign-In 常見問題

#### 1. 點擊登入沒反應

**原因**：SHA-1 指紋不正確或未新增到 Google Cloud Console

**解決方案**：
- 重新檢查 SHA-1 是否正確
- 確認 SHA-1 已新增到 Google Cloud Console
- 等待 5-10 分鐘讓設定生效

---

#### 2. 顯示「開發者錯誤」

**原因**：Package Name 或 SHA-1 不匹配

**解決方案**：
- 檢查 `android/app/build.gradle.kts` 中的 `applicationId`
- 確認與 Google Cloud Console 中的 Package Name 一致
- 確認 SHA-1 指紋正確

---

#### 3. 只能在開發電腦上登入

**原因**：只新增了 Debug Keystore 的 SHA-1

**解決方案**：
- 如果是 Release APK，需要新增 Release Keystore 的 SHA-1
- 或者確保 Release APK 使用 Debug Keystore 簽名（開發階段）

---

## 📧 Email Authentication Deep Link 配置

> 設定 Supabase Email 確認連結的 Deep Link 處理，讓用戶點擊確認郵件後自動開啟 App

**最後更新**：2026年1月4日

---

### ✅ 已完成的配置

#### 1️⃣ **Flutter 端配置**

- ✅ 添加 `app_links` 依賴
- ✅ 配置 Android Deep Link（`AndroidManifest.xml`）
- ✅ 創建 `DeepLinkService`（處理 Email 確認連結）
- ✅ 在 `main.dart` 初始化 Deep Link 服務

#### 2️⃣ **Android 配置**

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

### 🚀 Supabase Dashboard 配置

#### 3️⃣ **Redirect URLs 配置**

1. 進入 [Supabase Dashboard](https://app.supabase.com/)
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

#### 4️⃣ **Email Templates 配置**（可選優化）

1. 進入 **Authentication** → **Email Templates**
2. 編輯 **Confirm signup** 模板
3. 確認 `{{ .ConfirmationURL }}` 會使用 Redirect URL

---

### 🧪 測試步驟

#### 測試流程：

1. **註冊新帳號**：
   ```dart
   await authService.signUpWithEmail(
     email: 'test@example.com',
     password: 'password123',
   );
   ```

2. **檢查郵件**：
   - 收到確認郵件
   - 確認連結格式：`com.example.strengthwise://login-callback#access_token=...`

3. **點擊確認連結**：
   - App 自動開啟
   - Deep Link Service 處理認證
   - 用戶自動登入 ✅

#### 驗證日誌：

```
[DEEP_LINK_SERVICE] 收到 Deep Link: com.example.strengthwise://login-callback#access_token=...
[DEEP_LINK_SERVICE] ✅ Email 確認成功，處理認證
[AUTH_SUPABASE] 用戶已登入: test@example.com
```

---

### 🐛 Deep Link 常見問題

#### 問題 1：點擊連結還是跳到 localhost

**原因**：Supabase Dashboard 未配置 Redirect URL

**解決**：完成「步驟 3️⃣」的 Supabase 配置

#### 問題 2：App 無法開啟

**原因**：Android Deep Link 配置錯誤

**檢查**：
```bash
# 驗證 Deep Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.example.strengthwise://login-callback#test=123" \
  com.example.strengthwise
```

#### 問題 3：確認後無法登入

**原因**：Supabase PKCE 流程配置

**檢查**：
- `SupabaseService` 已配置 `authFlowType: AuthFlowType.pkce` ✅
- Supabase Dashboard 啟用了 PKCE

---

### 📱 多平台支援

#### iOS 配置（未來）

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

#### Web 配置（未來）

**Redirect URL**:
```
https://yourdomain.com/auth/callback
```

---

### 🔒 安全性考量

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

## ✅ 發布檢查清單

### 發布前檢查

- [ ] 所有功能測試通過
- [ ] 更新版本號（`pubspec.yaml`）
- [ ] 更新 DEVELOPMENT_STATUS.md 變更記錄
- [ ] 清理調試代碼和註釋
- [ ] 運行 `flutter analyze` 檢查代碼
- [ ] 運行 `flutter test` 執行測試（如有）
- [ ] 構建 Release APK
- [ ] 在真實設備測試
- [ ] 測試 Google Sign-In 功能
- [ ] 檢查 APK 大小合理
- [ ] 準備發布說明

### Google Play 發布

- [ ] 創建 Release Keystore
- [ ] 新增 Release SHA-1 到 Google Cloud Console
- [ ] 構建 AAB（`flutter build appbundle --release`）
- [ ] 準備應用截圖（8 張）
- [ ] 準備應用描述（繁體中文 + 英文）
- [ ] 設定分級評定
- [ ] 填寫隱私權政策
- [ ] 上傳到 Google Play Console

---

## 📈 版本管理

### 更新版本號

編輯 `pubspec.yaml`：
```yaml
version: 1.0.0+1
         ^^^^^ ^^
         版本  構建號
```

- **版本號格式**：`主版本.次版本.修訂號`
- **構建號**：每次發布遞增

### 版本號規範

| 類型 | 主版本 | 次版本 | 修訂號 | 範例 |
|------|--------|--------|--------|------|
| 重大更新 | +1 | 0 | 0 | 1.0.0 → 2.0.0 |
| 新功能 | 不變 | +1 | 0 | 1.0.0 → 1.1.0 |
| Bug 修復 | 不變 | 不變 | +1 | 1.0.0 → 1.0.1 |

---

## 📝 參考資源

### Flutter 官方文檔
- [構建和發布 Android 應用](https://flutter.dev/docs/deployment/android)
- [應用簽名](https://developer.android.com/studio/publish/app-signing)

### Google 開發者文檔
- [OAuth 2.0 配置](https://developers.google.com/identity/protocols/oauth2)
- [Android OAuth 客戶端設定](https://developers.google.com/identity/sign-in/android/start-integrating)

### Supabase 文檔
- [Supabase Auth - Google Provider](https://supabase.com/docs/guides/auth/social-login/auth-google)
- [Supabase Auth Deep Links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)

### Flutter Packages
- [app_links Package](https://pub.dev/packages/app_links)

### Android 開發者文檔
- [Android App Links](https://developer.android.com/training/app-links)

---

**📝 文檔版本**: 2.0  
**📅 最後更新**: 2026-01-04  
**👥 維護者**: StrengthWise 開發團隊


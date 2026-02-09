# StrengthWise - 部署指南

> Release APK 構建、Google Sign-In 配置、CI/CD、發布流程

**最後更新**：2026-02-10（v5.2 - 新增混淆建置指令）

---

## 📋 目錄

1. [Web PWA 部署](#web-pwa-部署)
2. [Release APK 構建](#release-apk-構建)
3. [Google Play 上架](#google-play-上架)
4. [Google Sign-In 配置](#google-sign-in-配置)
5. [Email Deep Link 配置](#email-deep-link-配置)
6. [發布檢查清單](#發布檢查清單)

---

## 🌐 Web PWA 部署

> iOS 暫未上架，透過 PWA 讓用戶體驗接近原生 App

### Google OAuth Web 設定

**已完成配置**（2026-01-11）：

| 項目 | 值 |
|------|-----|
| Web Client ID | `254965941837-19m8q4n7snie04mph7g1nbdf345dldpc.apps.googleusercontent.com` |
| Redirect URI | `https://fihkhoogvkccgpbgjhpw.supabase.co/auth/v1/callback` |

**Supabase Client IDs 配置**：
```
254965941837-bp00e1l33hbvss4tpb94t9i16g8729e6.apps.googleusercontent.com,254965941837-4bv8622d876egpa9mdvpjveubavqr3hp.apps.googleusercontent.com,254965941837-19m8q4n7snie04mph7g1nbdf345dldpc.apps.googleusercontent.com
```

### 建構 Web 版本

```bash
# 建構 Web
flutter build web --release

# 輸出位置
build/web/
```

### Vercel 部署

**專案資訊**：

| 項目 | 值 |
|------|-----|
| 專案名稱 | `app-strengthwise-beta` |
| 正式 URL | https://app-strengthwise-beta.vercel.app |
| 最後部署 | 2026-01-17（v1.1.0）|

**部署步驟**：

```bash
# 1. 建置 Web
flutter build web --release

# 2. 部署到 Vercel
cd build/web
vercel --prod
```

**Google OAuth JavaScript Origins**（已配置）：
- `https://app-strengthwise-beta.vercel.app`

### PWA 安裝引導

| 平台 | 安裝方式 |
|------|----------|
| Android Chrome | 自動彈出「加到主畫面」提示 |
| iOS Safari | 手動「分享 → 加到主畫面」|

---

## 🚀 Release APK 構建

### 快速構建

```bash
# 構建 Release APK
flutter build apk --release

# APK 位置
build\app\outputs\flutter-apk\app-release.apk

# 安裝到手機
adb -s <DEVICE_ID> install -r build\app\outputs\flutter-apk\app-release.apk
```

### 構建選項

| 命令 | 用途 | 大小 |
|------|------|------|
| `flutter build apk --release` | 通用 APK | ~55 MB |
| `flutter build apk --release --split-per-abi` | 分架構 | ~18-20 MB |
| `flutter build appbundle --release` | Google Play | AAB |

### 程式碼混淆（建議用於正式發布）

```bash
# APK（含混淆 + debug info 分離）
flutter build apk --release --obfuscate --split-debug-info=build/debug-info

# AAB（Google Play 上架用）
flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info
```

> `--split-debug-info` 產出的 debug 符號檔案可用於 Crashlytics 等服務還原堆疊追蹤。

### 簽名配置（正式發布）

1. **創建簽名密鑰**：
```bash
keytool -genkey -v -keystore ~/strengthwise-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias strengthwise
```

2. **創建 `android/key.properties`**：
```properties
storePassword=密碼
keyPassword=密碼
keyAlias=strengthwise
storeFile=路徑/strengthwise-release-key.jks
```

3. **修改 `android/app/build.gradle.kts`**：配置 signingConfigs

---

## 📱 Google Play 上架

### 前置準備

1. **Google Play Console 帳號**（$25 USD 一次性費用）
2. **Release Keystore**（已配置於 `android/app/strengthwise-release.keystore`）
3. **隱私政策**（Google Docs 連結即可）

### 建構 AAB

```bash
# 建構 Release AAB
flutter build appbundle --release

# AAB 位置
build\app\outputs\bundle\release\app-release.aab
```

### 上傳流程

1. **Google Play Console** → 建立應用程式
   - 應用程式名稱：`StrengthWise`
   - 預設語言：繁體中文
   - 類型：應用程式
   - 收費：免費

2. **內部測試** → 建立新版本
   - 上傳 `app-release.aab`
   - 版本名稱：`1.0.0`
   - 版本資訊：功能說明

3. **測試人員** → 建立電子郵件名單
   - 新增測試人員 Email
   - 複製測試連結分享給測試人員

4. **取得測試連結**
   - 測試 → 內部測試 → 測試人員 → 複製連結
   - 或直接訪問：`https://play.google.com/apps/internaltest/{測試ID}`
   - ⚠️ 只有在名單中的 Email 帳號才能下載

5. **App Signing SHA-1**
   - 設定 → 應用程式完整性 → App signing key certificate
   - 複製 SHA-1 到 Google Cloud Console

### Release Keystore 資訊

```
檔案：android/app/strengthwise-release.keystore
密碼：strengthwise2026
Alias：strengthwise
```

⚠️ **重要**：備份 keystore 到安全位置！

### Google Play App Signing

| 鑰匙 | 管理者 | 用途 |
|------|--------|------|
| Upload Key（你的 keystore） | 你 | 簽署上傳的 AAB |
| App Signing Key | Google | 簽署給用戶下載的 APK |

遺失 Upload Key 可請 Google 重設，但建議備份。

---

## 🔐 Google Sign-In 配置

### 獲取 SHA-1 指紋

```bash
# 方法 1：Gradle
cd android && .\gradlew signingReport

# 方法 2：keytool（Debug）
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" \
  -alias androiddebugkey -storepass android | findstr SHA1
```

### 配置步驟

1. **Google Cloud Console**：
   - APIs & Services → Credentials
   - 編輯 OAuth 2.0 Client ID（Android）
   - 添加 SHA-1 fingerprint

2. **Supabase Dashboard**：
   - Authentication → Providers → Google
   - 確認 Client ID 和 Secret
   - 添加 Authorized Client IDs

### 常見問題

| 問題 | 原因 | 解決 |
|------|------|------|
| 點擊沒反應 | SHA-1 未配置 | 添加到 Google Cloud Console |
| 開發者錯誤 | Package Name 不匹配 | 檢查 applicationId |
| 只能開發機登入 | 只有 Debug SHA-1 | 添加 Release SHA-1 |

---

## 📧 Email Deep Link 配置

### Android 配置

**AndroidManifest.xml**：
```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data 
        android:scheme="com.strengthwise.fitness"
        android:host="login-callback" />
</intent-filter>
```

### Supabase 配置

1. **Authentication → URL Configuration**
2. **Redirect URLs** 添加：`com.strengthwise.fitness://login-callback`

### 測試驗證

```bash
# 驗證 Deep Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.strengthwise.fitness://login-callback#test=123" \
  com.strengthwise.fitness
```

---

## ✅ 發布檢查清單

### 發布前

- [ ] 更新版本號（`pubspec.yaml`）
- [ ] 運行 `flutter analyze`
- [ ] 構建 Release APK
- [ ] 測試 Google Sign-In
- [ ] 測試 Email Deep Link
- [ ] 在真實設備測試

### Google Play 發布

- [ ] 創建 Release Keystore
- [ ] 添加 Release SHA-1
- [ ] 構建 AAB
- [ ] 準備截圖和描述
- [ ] 設定分級評定
- [ ] 填寫隱私權政策

---

## 📈 版本號規範

```yaml
# pubspec.yaml
version: 1.0.0+1
         ^^^^^  ^
         版本   構建號
```

| 類型 | 版本變化 | 範例 |
|------|---------|------|
| 重大更新 | +1.0.0 | 1.0.0 → 2.0.0 |
| 新功能 | +0.1.0 | 1.0.0 → 1.1.0 |
| Bug 修復 | +0.0.1 | 1.0.0 → 1.0.1 |

---

## 🤖 CI/CD（GitHub Actions）

### 配置的 Secrets

| Secret 名稱 | 說明 |
|-------------|------|
| `KEYSTORE_BASE64` | Release Keystore 的 Base64 編碼 |
| `STORE_PASSWORD` | Keystore 密碼 |
| `KEY_PASSWORD` | Key 密碼 |
| `KEY_ALIAS` | Key 別名 |
| `GOOGLE_SERVICES_JSON` | Firebase 配置檔的 Base64 編碼 |

### 生成 Base64 編碼

**PowerShell**：
```powershell
# Keystore
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/strengthwise-release.keystore")) | Set-Clipboard

# google-services.json
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android/app/google-services.json")) | Set-Clipboard
```

### Gradle 鏡像配置

為避免 GitHub Actions 的 Maven Central 403 問題，已配置阿里雲鏡像：

- `android/settings.gradle.kts` - pluginManagement repositories
- `android/build.gradle.kts` - buildscript + allprojects + subprojects

**優先順序**：
1. `google()` - Firebase plugins
2. 阿里雲鏡像 - 替代 Maven Central
3. `mavenCentral()` - 備用

### CI 工作流程

| Job | 說明 | 觸發條件 |
|-----|------|----------|
| `analyze_and_test` | flutter analyze + test | 所有 push/PR |
| `build_android` | APK + AAB 建置 | 僅 master/main |

---

## 📝 參考資源

- [Flutter Android 部署](https://flutter.dev/docs/deployment/android)
- [Supabase Auth Deep Links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [app_links Package](https://pub.dev/packages/app_links)

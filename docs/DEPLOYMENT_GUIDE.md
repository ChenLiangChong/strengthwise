# StrengthWise - 部署指南

> Release APK 構建、Google Sign-In 配置、發布流程

**最後更新**：2026-01-05

---

## 📋 目錄

1. [Release APK 構建](#release-apk-構建)
2. [Google Sign-In 配置](#google-sign-in-配置)
3. [Email Deep Link 配置](#email-deep-link-配置)
4. [發布檢查清單](#發布檢查清單)

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
        android:scheme="com.example.strengthwise"
        android:host="login-callback" />
</intent-filter>
```

### Supabase 配置

1. **Authentication → URL Configuration**
2. **Redirect URLs** 添加：`com.example.strengthwise://login-callback`

### 測試驗證

```bash
# 驗證 Deep Link
adb shell am start -W -a android.intent.action.VIEW \
  -d "com.example.strengthwise://login-callback#test=123" \
  com.example.strengthwise
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

## 📝 參考資源

- [Flutter Android 部署](https://flutter.dev/docs/deployment/android)
- [Supabase Auth Deep Links](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [app_links Package](https://pub.dev/packages/app_links)

# StrengthWise - 部署指南

> Release APK 構建、Google Sign-In 配置、發布流程完整指南

**最後更新**：2024-12-26

---

## 📋 目錄

1. [Release APK 構建](#release-apk-構建)
2. [Google Sign-In 配置](#google-sign-in-配置)
3. [發布檢查清單](#發布檢查清單)
4. [版本管理](#版本管理)

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

---

**📝 文檔版本**: 1.0  
**📅 最後更新**: 2024-12-26  
**👥 維護者**: StrengthWise 開發團隊


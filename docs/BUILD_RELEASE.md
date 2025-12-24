# StrengthWise - Release APK 構建指南

> 快速構建和安裝 Release 版本 APK

**最後更新**：2024年12月24日

---

## 🚀 快速構建流程

### 方法 1：構建並自動安裝（推薦）

```bash
# 1. 確認手機已連接
adb devices

# 2. 構建 Release APK
flutter build apk --release

# 3. 安裝到手機
adb -s N1AIGF001374FLL install -r build\app\outputs\flutter-apk\app-release.apk
```

### 方法 2：只構建 APK

```bash
# 構建 Release APK
flutter build apk --release

# APK 位置：
# build\app\outputs\flutter-apk\app-release.apk
```

---

## 📦 APK 位置

構建成功後，APK 會生成在：
```
D:\gitDir\strengthwise\build\app\outputs\flutter-apk\app-release.apk
```

---

## 📱 安裝方法

### 方法 1：通過 ADB 安裝（電腦連接手機）

```bash
# 替換為實際的設備 ID
adb -s N1AIGF001374FLL install -r build\app\outputs\flutter-apk\app-release.apk
```

### 方法 2：手動安裝（無需電腦）

1. 將 `app-release.apk` 複製到手機
2. 在手機上打開文件管理器
3. 點擊 APK 文件
4. 允許安裝未知來源應用（首次需要）
5. 點擊「安裝」

---

## 🔐 簽名 APK（正式發布時需要）

### 創建簽名密鑰（只需做一次）

```bash
keytool -genkey -v -keystore ~/strengthwise-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias strengthwise
```

### 配置簽名

1. 創建 `android/key.properties`：
```properties
storePassword=你的密碼
keyPassword=你的密碼
keyAlias=strengthwise
storeFile=路徑/strengthwise-release-key.jks
```

2. 修改 `android/app/build.gradle.kts`：
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

3. 構建簽名的 APK：
```bash
flutter build apk --release
```

---

## 📊 構建選項

### 構建單個 APK（通用）
```bash
flutter build apk --release
# 生成: app-release.apk (~55 MB)
```

### 構建分架構 APK（更小）
```bash
flutter build apk --release --split-per-abi
# 生成:
# - app-armeabi-v7a-release.apk (~18 MB)
# - app-arm64-v8a-release.apk (~19 MB)
# - app-x86_64-release.apk (~20 MB)
```

### 構建 AAB（Google Play 商店）
```bash
flutter build appbundle --release
# 生成: app-release.aab
```

---

## 🐛 常見問題

### 1. 手機無法檢測到

```bash
# 重啟 ADB
adb kill-server
adb start-server
adb devices
```

### 2. 安裝失敗

```bash
# 先卸載舊版本
adb -s N1AIGF001374FLL uninstall com.example.strengthwise

# 重新安裝
adb -s N1AIGF001374FLL install build\app\outputs\flutter-apk\app-release.apk
```

### 3. 構建失敗

```bash
# 清理構建緩存
flutter clean
flutter pub get

# 重新構建
flutter build apk --release
```

---

## 📈 版本管理

### 更新版本號

編輯 `pubspec.yaml`：
```yaml
version: 1.0.0+1
         ^^^^^ ^^
         版本  構建號
```

- 版本號格式：`主版本.次版本.修訂號`
- 構建號：每次發布遞增

---

## ✅ 發布前檢查清單

- [ ] 所有功能測試通過
- [ ] 更新版本號
- [ ] 更新 CHANGELOG.md
- [ ] 清理調試代碼和註釋
- [ ] 運行 `flutter analyze` 檢查代碼
- [ ] 運行 `flutter test` 執行測試
- [ ] 構建 Release APK
- [ ] 在真實設備測試
- [ ] 檢查 APK 大小合理
- [ ] 準備發布說明

---

## 📝 參考

- [Flutter 官方文檔：構建和發布 Android 應用](https://flutter.dev/docs/deployment/android)
- [Android 應用簽名](https://developer.android.com/studio/publish/app-signing)


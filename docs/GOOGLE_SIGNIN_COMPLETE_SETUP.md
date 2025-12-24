# Google Sign-In 完整配置指南

> 確保其他手機也能正常使用 Google 登入

**最後更新**：2024年12月24日

---

## 🎯 目標

讓你構建的 APK 在**任何手機**上都能正常使用 Google 登入。

---

## ✅ 必要步驟（完整流程）

### 步驟 1：獲取 Release APK 的 SHA-1 指紋

#### 1.1 檢查當前使用的 Keystore

你的 Release APK 目前使用的是 **Debug Keystore**（因為沒有配置 Release Keystore）。

#### 1.2 獲取 Debug Keystore 的 SHA-1

**方法 1：通過 Gradle**

```bash
cd android
.\gradlew signingReport
```

在輸出中找到：
```
Variant: release
Config: debug
Store: C:\Users\charl\.android\debug.keystore
Alias: androiddebugkey
SHA1: BB:81:9A:9F:7A:E1:E6:5F:D8:86:2E:FC:4D:8B:D0:94:E1:EA:70:69
```

**方法 2：直接使用 keytool**

打開**命令提示符**（不是 PowerShell）：

```cmd
cd /d "%USERPROFILE%\.android"
keytool -list -v -keystore debug.keystore -alias androiddebugkey -storepass android -keypass android | findstr SHA1
```

或者使用 Android Studio 的 keytool：

```cmd
"C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

---

### 步驟 2：在 Firebase Console 添加 SHA-1

1. **打開 Firebase Console**
   - 前往：https://console.firebase.google.com/
   - 選擇專案：`strengthwise-91f02`

2. **進入專案設定**
   - 點擊左側齒輪圖標 ⚙️
   - 選擇「專案設定」

3. **找到你的 Android 應用**
   - 滾動到「你的應用程式」區域
   - 找到 `com.example.strengthwise`

4. **添加 SHA-1 指紋**
   - 滾動到「SHA 憑證指紋」區域
   - 點擊「新增指紋」
   - 貼上步驟 1 獲取的 SHA-1（格式：`BB:81:9A:...`）
   - 點擊「儲存」

5. **檢查現有指紋**
   
   你的 `google-services.json` 中已經有兩個 SHA-1：
   - `bb819a9f7ae1e65fd8862efc4d8bd094e1ea7069`
   - `245c4c390acd5ecb42f1fbd4678bb6e2349a49aa`
   
   確認你剛獲取的 SHA-1 是否已經在列表中（去掉冒號後比對）。

---

### 步驟 3：啟用 Google Sign-In Provider

1. **在 Firebase Console 中**
   - 左側選單 → 「Authentication」
   - 頂部選擇「Sign-in method」標籤

2. **啟用 Google 提供者**
   - 找到「Google」項目
   - 點擊編輯圖標（鉛筆）
   - 切換「啟用」開關
   - 輸入專案支援電子郵件
   - 點擊「儲存」

3. **檢查狀態**
   - Google 提供者應該顯示為「已啟用」✅

---

### 步驟 4：下載更新的 google-services.json

1. **返回專案設定**
   - 點擊左側齒輪圖標 ⚙️
   - 選擇「專案設定」

2. **下載配置文件**
   - 找到你的 Android 應用 `com.example.strengthwise`
   - 點擊「下載 google-services.json」按鈕
   - 保存文件

3. **替換舊文件**
   ```bash
   # 備份舊文件（可選）
   copy android\app\google-services.json android\app\google-services.json.backup
   
   # 將下載的文件複製到正確位置
   copy "下載路徑\google-services.json" android\app\google-services.json
   ```

---

### 步驟 5：重新構建 Release APK

```bash
# 清理舊的構建
flutter clean

# 獲取依賴
flutter pub get

# 構建新的 Release APK
flutter build apk --release
```

---

### 步驟 6：測試

#### 6.1 在你的手機上測試

```bash
# 卸載舊版本（重要！）
adb -s N1AIGF001374FLL uninstall com.example.strengthwise

# 安裝新版本
adb -s N1AIGF001374FLL install build\app\outputs\flutter-apk\app-release.apk

# 查看日誌
adb -s N1AIGF001374FLL logcat | grep -i "google\|auth"
```

#### 6.2 在其他手機上測試

1. 將 `app-release.apk` 複製到其他手機
2. 安裝並打開應用
3. 嘗試 Google 登入
4. 如果失敗，查看錯誤信息

---

## 🔍 故障排除

### 問題 1：「開發者錯誤」或「12500 錯誤」

**原因**：SHA-1 指紋不正確或未添加到 Firebase

**解決方案**：
1. 重新獲取 SHA-1（確保使用正確的 keystore）
2. 確認 SHA-1 已添加到 Firebase Console
3. 下載最新的 google-services.json
4. 重新構建 APK

---

### 問題 2：「未授權的 client」

**原因**：Google Sign-In Provider 未啟用

**解決方案**：
1. 檢查 Firebase Console → Authentication → Sign-in method
2. 確保 Google 提供者顯示「已啟用」
3. 下載最新的 google-services.json

---

### 問題 3：在模擬器上無法登入

**原因**：模擬器可能沒有 Google Play Services

**解決方案**：
- 僅在真實設備上測試 Google Sign-In
- 或使用包含 Google Play 的模擬器映像

---

## 📋 快速檢查清單

在分享 APK 給其他人之前，確認：

- [ ] **步驟 1**：已獲取 Release APK 的 SHA-1
- [ ] **步驟 2**：SHA-1 已添加到 Firebase Console
- [ ] **步驟 3**：Google Sign-In Provider 已啟用
- [ ] **步驟 4**：已下載最新的 google-services.json
- [ ] **步驟 5**：使用最新配置重新構建 APK
- [ ] **步驟 6**：在至少 2 台不同手機上測試成功

---

## 🔐 正式發布（可選 - 使用 Release Keystore）

### 為什麼需要 Release Keystore？

- Debug Keystore 不適合正式發布
- 每台電腦的 Debug Keystore 可能不同
- Release Keystore 由你控制，更安全

### 創建 Release Keystore

```bash
keytool -genkey -v -keystore ~/strengthwise-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias strengthwise
```

### 配置 Release Keystore

1. **創建 `android/key.properties`**

```properties
storePassword=你的密碼
keyPassword=你的密碼
keyAlias=strengthwise
storeFile=C:/Users/你的用戶名/strengthwise-release-key.jks
```

2. **修改 `android/app/build.gradle.kts`**

在 `android {` 區塊前添加：

```kotlin
// 讀取簽名配置
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

在 `android {` 區塊內添加：

```kotlin
signingConfigs {
    create("release") {
        keyAlias = keystoreProperties["keyAlias"] as String?
        keyPassword = keystoreProperties["keyPassword"] as String?
        storeFile = keystoreProperties["storeFile"]?.let { file(it) }
        storePassword = keystoreProperties["storePassword"] as String?
    }
}

buildTypes {
    getByName("release") {
        signingConfig = signingConfigs.getByName("release")
        // ... 其他配置
    }
}
```

3. **獲取 Release Keystore 的 SHA-1**

```bash
keytool -list -v -keystore ~/strengthwise-release-key.jks -alias strengthwise
```

4. **添加到 Firebase Console**（重複步驟 2）

5. **重新構建**

```bash
flutter build apk --release
```

---

## 📝 當前狀態

根據你的 `google-services.json`，已經有以下配置：

✅ **已配置的 SHA-1 指紋**：
1. `bb819a9f7ae1e65fd8862efc4d8bd094e1ea7069`
2. `245c4c390acd5ecb42f1fbd4678bb6e2349a49aa`

⚠️ **需要確認**：
- [ ] Google Sign-In Provider 是否已啟用？
- [ ] 當前 Release APK 使用的 SHA-1 是否在列表中？
- [ ] google-services.json 是否是最新版本？

---

## 🎯 下一步行動

### 立即執行（推薦）：

1. **獲取當前 SHA-1**
   ```bash
   cd android
   .\gradlew signingReport
   ```
   
2. **檢查 Firebase Console**
   - 前往：https://console.firebase.google.com/
   - 確認 Google Sign-In 已啟用
   - 確認 SHA-1 已添加

3. **如果有任何變更**
   - 下載最新 google-services.json
   - 重新構建 APK
   - 在多台設備測試

---

## 💡 提示

- 每次更改 keystore 或添加新的 SHA-1，都需要重新下載 google-services.json
- 測試時建議使用不同的 Google 帳號
- 如果在其他手機上失敗，查看 logcat 日誌獲取詳細錯誤信息

---

**需要幫助？** 執行以下命令並提供輸出：

```bash
cd android
.\gradlew signingReport > signing-report.txt
```

然後檢查 `signing-report.txt` 文件中的 SHA-1。


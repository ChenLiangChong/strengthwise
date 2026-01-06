---
description: "部署流程規範：Android APK、iOS、Google Sign-In、Supabase 配置。"
globs: android/**/*,ios/**/*,pubspec.yaml
alwaysApply: false
---

# 部署流程規範

<critical>
1. Release 前必須更新版本號（`pubspec.yaml`）
2. `key.properties` 不可提交到 Git
3. SHA-1 必須添加到 Google Cloud Console
</critical>

## 📱 建置命令

```bash
# Release APK
flutter build apk --release

# Google Play AAB
flutter build appbundle --release
```

## 🔐 Google Sign-In

```bash
# 獲取 SHA-1
cd android && .\gradlew signingReport
```

## 📋 發布檢查清單

- [ ] 更新版本號（`pubspec.yaml`）
- [ ] SHA-1 已添加到 Google Cloud Console
- [ ] 測試 Google Sign-In
- [ ] 測試 Deep Link

詳見：`docs/DEPLOYMENT_GUIDE.md`

---

## 📝 文檔維護

### DEPLOYMENT_GUIDE.md 結構

```
DEPLOYMENT_GUIDE.md
├── APK 構建（命令、選項）
├── Google Sign-In 配置
├── Deep Link 配置
├── 發布檢查清單
└── 版本號規範
```

### 禁止內容

<critical>
- 密鑰、密碼等敏感資訊
- 過時的配置步驟
- 重複的命令說明
</critical>


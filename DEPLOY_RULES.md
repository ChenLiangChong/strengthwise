# Firestore 規則部署步驟

## ✅ 已完成
1. ✅ 安裝 Firebase CLI
2. ✅ 創建 `firebase.json` 配置文件
3. ✅ 創建 `.firebaserc` 項目配置
4. ✅ 準備好 `firestore.rules` 規則文件

## 🔄 接下來需要你手動完成

### 步驟 1：登入 Firebase

在終端機運行：

```bash
firebase login
```

這會：
1. 打開瀏覽器窗口
2. 讓你選擇 Google 帳號（需要有 `strengthwise-91f02` 項目的權限）
3. 授權 Firebase CLI 訪問

### 步驟 2：部署規則

登入成功後，運行：

```bash
firebase deploy --only firestore:rules
```

這會將 `firestore.rules` 文件部署到 Firebase 項目。

### 步驟 3：驗證部署

部署成功後，你應該會看到類似訊息：
```
✔  firestore: deployed rules in firestore.rules successfully
```

## 📝 規則說明

部署的規則允許：
- ✅ 所有用戶可以**讀取** `exerciseTypes`、`bodyParts`、`exercises`（公開數據）
- ✅ 已認證用戶可以**寫入**這些集合
- 🔒 用戶數據、訓練計劃、預約需要認證才能訪問

## 🚀 快速命令（複製貼上）

```bash
# 1. 登入
firebase login

# 2. 部署規則
firebase deploy --only firestore:rules
```

## ❓ 遇到問題？

如果遇到權限錯誤：
- 確保你的 Google 帳號有 `strengthwise-91f02` 項目的管理員權限
- 可以在 Firebase 控制台檢查：https://console.firebase.google.com/project/strengthwise-91f02/settings/iam

如果不想使用 CLI，也可以直接在 Firebase 控制台手動複製貼上規則：
- 訪問：https://console.firebase.google.com/project/strengthwise-91f02/firestore/rules
- 複製 `firestore.rules` 文件的內容
- 貼到規則編輯器並點擊「發布」


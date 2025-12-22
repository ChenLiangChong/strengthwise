# Scripts - 工具腳本

> 專案中的 Python 和 Dart 工具腳本

---

## 📁 腳本列表

### Python 腳本

#### 1. `import_exercises.py` - 運動庫匯入
**用途**：批次匯入運動動作數據到 Firestore

**使用方式**：
```bash
python scripts/import_exercises.py
```

**需求**：
- Python 3.x
- firebase-admin
- 需要 `strengthwise-service-account.json` 服務帳號金鑰

---

#### 2. `fillNull.py` - 資料欄位修補
**用途**：修補 Firestore 中缺失的欄位

**使用方式**：
```bash
python scripts/fillNull.py
```

**注意**：執行前請先備份資料庫！

---

#### 3. `analyze_firestore.py` - Firestore 分析（版本 1）
**用途**：分析 Firestore 資料庫結構

**使用方式**：
```bash
python scripts/analyze_firestore.py
```

**輸出**：生成 `firestore_analysis.json` 和 `firestore_analysis.md`

---

#### 4. `analyze_firestore_from_code.py` - Firestore 分析（版本 2）
**用途**：從代碼中分析 Firestore 使用情況

**使用方式**：
```bash
python scripts/analyze_firestore_from_code.py
```

---

#### 5. `user_profile_app.py` - 用戶資料分析工具
**用途**：分析和處理用戶資料

**使用方式**：
```bash
python scripts/user_profile_app.py
```

---

### Dart 腳本

#### `create_test_template.dart` - 測試模板生成
**用途**：生成測試用的訓練模板

**使用方式**：
```bash
dart run scripts/create_test_template.dart
```

---

## 🔧 環境設置

### Python 依賴

安裝所需的 Python 套件：

```bash
pip install -r requirements.txt
```

主要依賴：
- `firebase-admin` - Firebase 管理 SDK
- 其他依賴請參考 `requirements.txt`

### Firebase 服務帳號

大部分腳本需要 Firebase 服務帳號金鑰：

1. 從 [Firebase Console](https://console.firebase.google.com/) 下載服務帳號金鑰
2. 將其命名為 `strengthwise-service-account.json`
3. 放在專案根目錄

**⚠️ 注意**：不要將服務帳號金鑰提交到 Git！

---

## 📝 使用注意事項

### 資料庫操作腳本

執行以下腳本前請**務必備份資料庫**：
- `fillNull.py`
- `import_exercises.py`

### 分析腳本

分析腳本是**只讀操作**，不會修改資料：
- `analyze_firestore.py`
- `analyze_firestore_from_code.py`
- `user_profile_app.py`

---

## 🚨 安全提醒

1. **不要分享服務帳號金鑰**
2. **執行前先測試**：在測試環境先執行
3. **備份資料**：執行寫入操作前先備份
4. **檢查權限**：確認服務帳號有足夠權限

---

## 📚 相關文檔

- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
- [Firestore 文檔](https://firebase.google.com/docs/firestore)
- 專案資料庫設計：`docs/DATABASE_DESIGN.md`

---

**最後更新**：2024年12月22日


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

#### 6. `analyze_body_parts.py` - 身體部位分類分析 ⭐ NEW
**用途**：分析 Firestore 中的身體部位分類，找出重複和需要合併的項目

**使用方式**：
```bash
python scripts/analyze_body_parts.py
```

**輸出**：
- 列出所有現有的身體部位
- 分析 exercise 集合中的使用情況
- 生成合併計劃（`body_parts_merge_plan.json`）
- 預估合併後的結果

**特點**：
- ✅ 只讀操作，不修改資料
- ✅ 生成詳細的分析報告
- ✅ 識別重複項目（如：胸/胸部、肩/肩部）

---

#### 7. `merge_body_parts.py` - 身體部位合併執行 ⭐ NEW
**用途**：統一和合併 Firestore 中的身體部位分類

**使用方式**：
```bash
python scripts/merge_body_parts.py
```

**執行內容**：
1. **階段 1**：更新 exercise 集合的 bodyParts 欄位
2. **階段 2**：重建 bodyParts 集合，移除重複項
3. **階段 3**：驗證結果

**合併規則**：
- 胸部 → 胸
- 肩部 → 肩
- 背部 → 背
- 腿部 → 腿
- 肩、背 → 拆分為 肩 + 背

**⚠️ 重要**：
- 執行前**務必備份 Firestore 資料**
- 建議在**測試環境**先執行
- 執行時間約 2-5 分鐘
- 完成後需清除應用快取

**詳細說明**：請參考 `BODY_PARTS_MERGE_README.md`

---

### Dart 腳本

#### 1. `create_test_template.dart` - 測試模板生成
**用途**：生成測試用的訓練模板

**使用方式**：
```bash
dart run scripts/create_test_template.dart
```

---

#### 2. `clear_exercise_cache.dart` - 清除運動庫快取 ⭐ NEW
**用途**：清除應用中的運動庫快取，確保使用最新資料

**使用方式**：
```bash
dart scripts/clear_exercise_cache.dart
```

**適用場景**：
- 更新 Firestore 資料後
- 執行身體部位合併後
- 應用顯示舊資料時

**注意**：如果腳本無法找到快取文件，請在應用中手動清除或重新安裝應用

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
- `merge_body_parts.py` ⚠️ **會修改大量資料**

### 分析腳本

分析腳本是**只讀操作**，不會修改資料：
- `analyze_firestore.py`
- `analyze_firestore_from_code.py`
- `user_profile_app.py`
- `analyze_body_parts.py` ✅ **推薦先執行**

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
- 身體部位合併指南：`scripts/BODY_PARTS_MERGE_README.md` ⭐

---

## 🔄 常見工作流程

### 身體部位資料整理
```bash
# 1. 分析現有資料
python scripts/analyze_body_parts.py

# 2. 查看分析結果
cat body_parts_merge_plan.json

# 3. 執行合併（謹慎！）
python scripts/merge_body_parts.py

# 4. 清除快取
dart scripts/clear_exercise_cache.dart

# 5. 驗證應用
flutter run
```

### 重新匯入運動資料
```bash
# 1. 備份資料庫
# （在 Firebase Console 執行）

# 2. 匯入新資料
python scripts/import_exercises.py

# 3. 清除快取
dart scripts/clear_exercise_cache.dart
```

---

**最後更新**：2024年12月23日


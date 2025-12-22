# 🚀 Strengthwise 環境設置完整指南

## 📋 需要安裝的工具清單

| 工具 | 必需性 | 用途 | 狀態 |
|------|--------|------|------|
| **Python 3.11+** | ✅ 必需 | 執行資料處理腳本 | ✅ 已設置（Conda） |
| **Flutter SDK** | ✅ 必需 | Flutter 應用開發 | ⏳ 更新中 |
| **Node.js** | ⚠️ 推薦 | Firebase CLI | ❓ 待檢查 |
| **Firebase CLI** | ⚠️ 可選 | 部署 Firestore 規則 | ❓ 待安裝 |
| **Git** | ✅ 必需 | 版本控制 | ✅ 通常已安裝 |

---

## ✅ 已完成的工作

### 1. Python 環境（Conda）
- ✅ 建立了 Conda 環境：`strengthwise` (Python 3.11)
- ✅ 安裝了所有 Python 依賴：
  - pandas >= 2.0.0
  - numpy >= 1.24.0
  - deep-translator >= 1.11.4
  - firebase-admin >= 6.0.0

### 2. 文件和腳本
- ✅ `requirements.txt` - Python 依賴
- ✅ `環境安裝指南.md` - 完整安裝指南
- ✅ `快速開始指南.md` - 快速開始
- ✅ `安裝Node.js指南.md` - Node.js 安裝指南
- ✅ `檢查環境.ps1` - 環境檢查腳本

---

## 🔧 下一步：安裝 Node.js

### 快速安裝步驟

1. **下載 Node.js**
   - 訪問：https://nodejs.org/
   - 下載 **LTS 版本**（推薦）
   - 選擇 Windows 64-bit 安裝程式

2. **安裝 Node.js**
   - 執行安裝程式
   - **重要**：勾選 "Add to PATH"
   - 可以選擇安裝到 D 盤：`D:\Programs\nodejs`

3. **驗證安裝**
   ```powershell
   # 開啟新的 PowerShell 視窗
   node --version
   npm --version
   ```

4. **安裝 Firebase CLI**
   ```powershell
   npm install -g firebase-tools
   firebase --version
   ```

---

## 📝 詳細安裝指南

### Node.js 安裝
👉 查看：`安裝Node.js指南.md`

### Python/Conda 設置
👉 查看：`環境安裝指南.md`

### Flutter 設置
👉 查看：`環境安裝指南.md`

---

## 🔍 檢查環境狀態

執行以下命令檢查所有工具：

```powershell
# 檢查 Python
python --version
conda --version
conda env list

# 檢查 Flutter
flutter --version
flutter doctor

# 檢查 Node.js（安裝後）
node --version
npm --version

# 檢查 Firebase CLI（安裝後）
firebase --version
```

---

## 🎯 快速開始

1. **啟動 Python 環境**
   ```powershell
   conda activate strengthwise
   ```

2. **等待 Flutter 更新完成**
   ```powershell
   flutter upgrade  # 如果還沒完成
   flutter pub get
   ```

3. **安裝 Node.js**（如果還沒有）
   - 參考：`安裝Node.js指南.md`

4. **執行應用**
   ```powershell
   flutter run -d chrome  # Web
   flutter run -d windows # Windows
   ```

---

## 📚 相關文件

- `環境安裝指南.md` - 完整安裝指南
- `快速開始指南.md` - 快速開始步驟
- `安裝Node.js指南.md` - Node.js 詳細安裝指南
- `環境設置總結.md` - 設置進度總結

---

## 🆘 需要幫助？

如果遇到問題，請查看相應的安裝指南文件，或執行：

```powershell
# 檢查環境（如果腳本可以執行）
powershell -ExecutionPolicy Bypass -File 檢查環境.ps1
```

---

**當前進度：約 80% 完成**

剩餘工作：
- [ ] 等待 Flutter 更新完成
- [ ] 安裝 Node.js
- [ ] 安裝 Firebase CLI（可選）
- [ ] 執行 `flutter pub get`


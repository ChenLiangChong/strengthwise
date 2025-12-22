# Firebase 认证设置指南

要使用 Python 脚本分析 Firestore 数据库，需要先设置 Firebase 认证。

## 方案 1：使用服务账号密钥文件（推荐）

### 步骤 1：创建服务账号密钥

1. 访问 [Firebase Console](https://console.firebase.google.com/)
2. 选择项目：**strengthwise-91f02**
3. 点击左侧菜单的 **⚙️ 项目设置** (Project Settings)
4. 切换到 **服务账号** (Service Accounts) 标签
5. 点击 **生成新的私钥** (Generate New Private Key)
6. 下载 JSON 文件（例如：`strengthwise-service-account.json`）
7. **重要**：将文件保存到项目根目录，但**不要提交到 Git**（已添加到 .gitignore）

### 步骤 2：设置环境变量

**Windows PowerShell:**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="D:\git dir\strengthwise\strengthwise-service-account.json"
```

**Windows CMD:**
```cmd
set GOOGLE_APPLICATION_CREDENTIALS=D:\git dir\strengthwise\strengthwise-service-account.json
```

**永久设置（推荐）:**
1. 右键点击 **此电脑** → **属性**
2. 点击 **高级系统设置**
3. 点击 **环境变量**
4. 在 **用户变量** 中点击 **新建**
5. 变量名：`GOOGLE_APPLICATION_CREDENTIALS`
6. 变量值：`D:\git dir\strengthwise\strengthwise-service-account.json`

### 步骤 3：运行分析脚本

```bash
python analyze_firestore.py
```

---

## 方案 2：使用 gcloud CLI（需要安装 Google Cloud SDK）

### 步骤 1：安装 Google Cloud SDK

1. 下载并安装：[Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
2. 或使用 Chocolatey（如果已安装）：
   ```powershell
   choco install gcloudsdk
   ```

### 步骤 2：登录并设置应用默认凭据

```bash
# 登录 Google Cloud
gcloud auth login

# 设置应用默认凭据
gcloud auth application-default login

# 设置项目
gcloud config set project strengthwise-91f02
```

### 步骤 3：运行分析脚本

```bash
python analyze_firestore.py
```

---

## 方案 3：直接在脚本中指定密钥文件路径

如果不想设置环境变量，可以修改脚本直接指定密钥文件路径。

修改 `analyze_firestore.py` 中的初始化部分：

```python
# 直接指定密钥文件路径
cred = credentials.Certificate('strengthwise-service-account.json')
firebase_admin.initialize_app(cred, {
    'projectId': 'strengthwise-91f02',
})
```

---

## 验证设置

运行以下命令验证认证是否成功：

```bash
python -c "import firebase_admin; from firebase_admin import credentials, firestore; cred = credentials.ApplicationDefault(); firebase_admin.initialize_app(cred, {'projectId': 'strengthwise-91f02'}); db = firestore.client(); print('认证成功！')"
```

---

## 安全注意事项

⚠️ **重要**：
- 服务账号密钥文件包含敏感信息，**不要提交到 Git**
- 已添加到 `.gitignore` 中
- 如果密钥泄露，请立即在 Firebase Console 中删除并重新生成

---

## 故障排除

### 错误：DefaultCredentialsError

**原因**：未找到应用默认凭据

**解决方法**：
- 检查环境变量 `GOOGLE_APPLICATION_CREDENTIALS` 是否正确设置
- 或使用方案 3，直接在脚本中指定密钥文件路径

### 错误：Permission denied

**原因**：服务账号没有 Firestore 读取权限

**解决方法**：
1. 在 Firebase Console 中，确保服务账号有 **Cloud Datastore User** 角色
2. 或在 IAM 中授予 **Firestore User** 权限

### 错误：Project not found

**原因**：项目 ID 不正确

**解决方法**：
- 检查项目 ID 是否为 `strengthwise-91f02`
- 在 Firebase Console 中确认项目 ID


# 個人資料頁面優化計劃

> 完善「我的」頁面功能與 UI/UX

**創建日期**：2024-12-26  
**狀態**：🚀 Phase 1 完成！

---

## ✅ 已完成（2024-12-26）

### Phase 1：視覺優化 ✅ **完成！**

#### 1. ✅ 個人資料卡片頭部優化（1h）
- ✅ 大頭像（80x80，從 40x40 升級）
- ✅ 角色標籤（⭐教練 / 🎓學員）浮動在頭像右下角
- ✅ 年齡 + 性別顯示（圖示 + 文字）
- ✅ 個人簡介顯示（最多 2 行）
- ✅ 快捷按鈕：「編輯資料」 +「身體數據」
- ✅ Card 包裹，提升視覺層次

#### 2. ✅ 詳細資訊卡片重設計（1h）
- ✅ 分組顯示：「基本資料」+「偏好設定」
- ✅ BMI 計算與分類（過輕/正常/過重/肥胖）
- ✅ **單位系統支援**：
  - 公制：cm, kg
  - 英制：feet & inches (ft' in"), lb
  - BMI 自動換算（公制/英制計算公式不同）
- ✅ 圓角容器背景（`surfaceVariant.withOpacity(0.3)`）
- ✅ 區段標題（Emoji + 文字）
- ✅ 資訊行間距優化（Divider 分隔）

#### 3. ✅ 功能菜單卡片化（30min）
- ✅ Card 包裹，增加視覺深度
- ✅ 圖示顏色分類：
  - 訓練記錄：Primary
  - 照片牆：Teal
  - 訓練備忘錄：Orange
- ✅ 圖示容器：圓角背景 + 淺色底
- ✅ 副標題顯示（功能說明）

#### 4. ✅ 主題切換卡片化
- ✅ Card 包裹，統一風格
- ✅ SegmentedButton 保持不變

#### 5. ✅ 登出按鈕優化
- ✅ 全寬按鈕
- ✅ Error 色系（紅色邊框 + 紅色文字）
- ✅ 移到最底部，避免誤觸

---

## 🗄️ 資料庫遷移

### ⚠️ 需要執行的遷移腳本

**文件**：`migrations/003_add_user_body_data_fields.sql`

**新增欄位**：
```sql
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS height DOUBLE PRECISION,  -- 身高（cm）
  ADD COLUMN IF NOT EXISTS weight DOUBLE PRECISION,  -- 體重（kg）
  ADD COLUMN IF NOT EXISTS age INTEGER,              -- 年齡（歲）
  ADD COLUMN IF NOT EXISTS gender TEXT;              -- 性別（男/女/其他）
```

**執行方式**：
1. **Supabase Dashboard**：
   - 登入 Supabase → 選擇專案
   - SQL Editor → New query
   - 複製 `migrations/003_add_user_body_data_fields.sql` 內容
   - 執行（Run）

2. **Supabase CLI**：
```bash
supabase migration new add_user_body_data_fields
# 將內容複製到生成的遷移文件
supabase db push
```

---

## 📊 現狀分析

### ✅ 已實作功能（可重用）

#### 1. 資料模型（`UserModel`）
| 欄位 | 類型 | 說明 | 狀態 |
|------|------|------|------|
| `uid` | String | 用戶 ID | ✅ 已實作 |
| `email` | String | 電子郵件 | ✅ 已實作 |
| `displayName` | String? | 顯示名稱 | ✅ 已實作 |
| `photoURL` | String? | 頭像 URL | ✅ 已實作 |
| `nickname` | String? | 暱稱 | ✅ 已實作 |
| `gender` | String? | 性別 | ✅ 已實作 |
| `height` | double? | 身高 (cm) | ✅ 已實作 |
| `weight` | double? | 體重 (kg) | ✅ 已實作 |
| `age` | int? | 年齡 | ✅ 已實作 |
| `birthDate` | DateTime? | 生日 | ✅ 已實作 |
| `isCoach` | bool | 教練身份 | ✅ 已實作 |
| `isStudent` | bool | 學員身份 | ✅ 已實作 |
| `bio` | String? | 個人簡介 | ✅ 已實作 |
| `unitSystem` | String? | 單位系統（公制/英制） | ✅ 已實作 |
| `lastLogin` | DateTime? | 最後登入時間 | ✅ 已實作 |

#### 2. 服務層（`IUserService`）
- ✅ `getCurrentUserProfile()` - 獲取當前用戶資料
- ✅ `updateUserProfile()` - 更新用戶資料
- ✅ `toggleUserRole()` - 切換教練/學員角色
- ✅ 頭像上傳功能（`ImagePicker` 整合）

#### 3. UI 元件
- ✅ 頭像顯示（`CircleAvatar` + 預設圖示）
- ✅ 基本資料編輯表單（`ProfileSettingsPage`）
- ✅ 角色切換開關（`SwitchListTile`）
- ✅ 主題切換器（淺色/深色/系統）
- ✅ 登出功能

---

## 🎯 待實作功能

### 1. 詳細資訊卡片（Priority: P0）

**目前問題**：
- 「詳細資訊」卡片只顯示「單位系統」和「角色」
- 缺少重要的身體數據和健身目標

**建議新增欄位**：
```dart
詳細資訊
├── 單位系統: 公制 / 英制           ✅ 已實作
├── 角色: 學員 / 教練                ✅ 已實作
├── 身高: 175 cm                    ✅ 資料已有，待顯示
├── 體重: 70 kg                     ✅ 資料已有，待顯示
├── 年齡: 28 歲                     ✅ 資料已有，待顯示
├── 性別: 男 / 女 / 其他            ✅ 資料已有，待顯示
└── 個人簡介: "..."                  ✅ 資料已有，待顯示
```

### 2. 訓練記錄頁面（Priority: P1）

**目前狀態**：空功能（`onTap: () {}`）

**建議實作**：
- 顯示所有已完成的訓練記錄（`WorkoutRecord`）
- 按日期排序（最新在前）
- 支援篩選（日期範圍、訓練類型）
- 點擊可查看詳細記錄
- 整合統計圖表（訓練頻率、總訓練量）

**可重用資源**：
- ✅ `WorkoutService.getUserRecords()` - 已實作
- ✅ `WorkoutRecord` 模型 - 已實作
- ✅ 統計頁面的卡片元件 - 可參考

### 3. 照片牆頁面（Priority: P2）

**目前狀態**：空功能

**建議實作**：
- 上傳訓練照片（Before/After、進步照）
- 網格佈局顯示（2x2 或 3x3）
- 點擊放大查看
- 按日期分組
- 可添加標籤（身體部位、訓練類型）

**待新增資源**：
- ❌ `PhotoModel` - 待創建
- ❌ `PhotoService` - 待創建
- ❌ Supabase Storage 整合 - 待設定

### 4. 訓練備忘錄頁面（Priority: P2）

**目前狀態**：空功能

**建議實作**：
- 記錄訓練心得、感受
- Markdown 支援
- 可附加到訓練記錄
- 標籤系統（#動作技巧、#飲食筆記、#心得）
- 搜尋功能

**待新增資源**：
- ❌ `NoteModel` - 待創建
- ❌ `NoteService` - 待創建
- ❌ Markdown 編輯器套件 - 待安裝

### 5. 身體數據頁面（Priority: P1）✅ **完成！**

**已實作**（2024-12-26）：
- ✅ 完整 CRUD 功能（創建、讀取、更新、刪除）
- ✅ 體重歷史趨勢圖（使用 `fl_chart`）
- ✅ BMI 歷史趨勢圖
- ✅ BMI 自動計算（基於用戶身高）
- ✅ BMI 分類顯示（過輕/正常/過重/肥胖）
- ✅ 體脂率記錄
- ✅ 肌肉量記錄
- ✅ 日期範圍篩選器
- ✅ 最新數據卡片（一目了然）
- ✅ 歷史記錄列表
- ✅ 新增記錄對話框（觸覺回饋）
- ✅ 刪除確認對話框
- ✅ 統一通知系統整合
- ✅ 遵循 Clean Architecture

**架構層級**：
- Model: `lib/models/body_data_record.dart`
- Service Interface: `lib/services/interfaces/i_body_data_service.dart`
- Service Impl: `lib/services/body_data_service_supabase.dart`
- Controller: `lib/controllers/body_data_controller.dart`
- UI: `lib/views/pages/profile/body_data_page.dart`
- Migration: `migrations/004_create_body_data_table.sql`（⚠️ 待執行）

---

## 🎨 UI/UX 優化建議

### 1. 個人資料卡片升級

**目前設計**：
```
┌────────────────────────────┐
│      [頭像]                │
│   charlie19960414          │
│      ✏️ [編輯按鈕]          │
└────────────────────────────┘
```

**建議升級**：
```
┌────────────────────────────┐
│      [大頭像 80x80]         │
│   charlie19960414 ⭐        │  ← 添加角色標籤（教練/學員）
│      28 歲 · 男             │  ← 添加基本資訊
│      ✏️ [編輯]  📊 [數據]   │  ← 添加快捷按鈕
└────────────────────────────┘
```

### 2. 詳細資訊卡片重設計

**目前設計**（陽春）：
```
┌────────────────────────────┐
│  詳細資訊                   │
│  單位系統          公制     │
│  角色              學員     │
└────────────────────────────┘
```

**建議升級**（資訊完整）：
```
┌────────────────────────────┐
│  📝 詳細資訊                │
│  ┌──────────────────────┐  │
│  │ 👤 基本資料          │  │
│  │   身高: 175 cm       │  │
│  │   體重: 70 kg        │  │
│  │   BMI: 22.9 (正常)   │  │
│  └──────────────────────┘  │
│  ┌──────────────────────┐  │
│  │ ⚙️ 偏好設定           │  │
│  │   單位: 公制         │  │
│  │   角色: 學員 🎓      │  │
│  └──────────────────────┘  │
└────────────────────────────┘
```

### 3. 菜單項目圖示更新

| 項目 | 現有圖示 | 建議圖示 | 顏色建議 |
|------|---------|---------|---------|
| 訓練記錄 | `calendar_today` | `fitness_center` | Primary |
| 照片牆 | `photo_library` | `photo_camera` | Teal |
| 訓練備忘錄 | `note` | `note_alt` | Orange |
| 身體數據 | `data_usage` | `monitor_weight` | Green |
| 編輯資料 | `settings` | `person_outline` | Blue |

### 4. 統一風格指南

**遵循 UI/UX Guidelines**：
- ✅ 使用 8 點網格系統（8, 16, 24, 32...）
- ✅ 最小觸控目標：48dp
- ✅ 語意化色彩（Primary, Surface, OnSurface）
- ✅ 圓角：卡片 16dp，按鈕 12dp
- ✅ 間距：內容 16dp，區塊 24dp
- ✅ 觸覺回饋：重要操作加入 `HapticFeedback`

---

## 📋 實作優先級

| 優先級 | 任務 | 預估工作量 | 依賴 |
|--------|------|-----------|------|
| **P0** | 優化詳細資訊卡片 | 1h | 無 |
| **P0** | 優化個人資料卡片頭部 | 1h | 無 |
| **P1** | 實作身體數據頁面 | 4h | 需新增 `BodyMeasurement` 模型 |
| **P1** | 實作訓練記錄頁面 | 3h | 無（可重用現有服務） |
| **P2** | 實作照片牆頁面 | 6h | 需 Supabase Storage |
| **P2** | 實作訓練備忘錄頁面 | 5h | 需 Markdown 套件 |
| **P3** | 優化編輯資料頁面 | 2h | 無 |

---

## 🚀 建議執行順序

### Phase 1：視覺優化（立即可做）
1. ✅ 優化個人資料卡片頭部（1h）
2. ✅ 優化詳細資訊卡片（1h）
3. ✅ 更新菜單項目圖示（30min）

### Phase 2：核心功能（下一步）
1. 實作身體數據頁面（4h）
2. 實作訓練記錄頁面（3h）

### Phase 3：進階功能（長期）
1. 實作照片牆（需規劃 Storage）
2. 實作訓練備忘錄（需 Markdown 支援）

---

## 📝 技術債務

**待解決問題**：
- ❌ 頭像上傳後未儲存到 Supabase Storage
- ❌ `ProfileSettingsPage` 欄位過多，建議分頁
- ❌ 缺少表單驗證（身高、體重合理範圍）
- ❌ 角色切換無二次確認（可能誤觸）

---

**參考文檔**：
- `docs/UI_UX_GUIDELINES.md` - UI/UX 設計規範
- `lib/models/user_model.dart` - 用戶資料模型
- `lib/services/interfaces/i_user_service.dart` - 用戶服務介面


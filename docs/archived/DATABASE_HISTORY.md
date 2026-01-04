# StrengthWise - 資料庫歷史記錄

> 資料庫遷移、修復、架構變更的歷史記錄

**最後更新**：2026-01-05

---

## 📦 遷移歷史

### Firestore → Supabase 遷移（2024-12-25）

**背景**：從 Firebase Firestore 遷移到 Supabase PostgreSQL

**遷移內容**：
- exercises：794 個動作（雙語完整）
- body_parts：8 個身體部位（雙語）
- exercise_types：3 個訓練類型（雙語）

**總計**：805 個文檔，0 個錯誤 ✅

**技術決策**：
- 使用 Supabase Auth 取代 Firebase Auth
- 保留 Firestore 相容 ID（20 字符）
- PostgreSQL Trigger 自動創建用戶資料

---

## 🔧 版本修復記錄

### v2.3: 資料庫修復與專案整理（2026-01-01）

**1. Personal Records Body Part 欄位**

**問題**：`personal_records.body_part` 一直是 `NULL`，導致視圖無資料

**解決方案**：
- 觸發器自動從 `exercises.body_parts[1]` 查詢並填入
- Migration：`009_v2_fixes.sql`

**2. 統計觸發器支援布林值**

**問題**：觸發器只支援 `completed: "true"` 字串格式

**解決方案**：
- 同時支援字串和布林值（向後相容 100%）
- Migration：`009_v2_fixes.sql`

**3. 可用時段查詢函數修復**

**問題**：`get_available_slots()` 函數邏輯錯誤

**解決方案**：
- 重新實作函數，正確查詢並排除已預約時段
- Migration：`008_fix_get_available_slots.sql`

---

### v2.2: 時區統一化（2025-01-02）

**問題**：時區轉換不一致，多處重複代碼

**解決方案**：
- 創建 `DateTimeUtils` 工具類（9 個方法）
- 全項目統一使用（40+ 個文件）
- 消除 120+ 處重複代碼

**技術決策**：
- Model 層返回本地時間
- Service 層儲存 UTC
- UI 層零轉換

---

## 📊 架構變更記錄

### v2.0 Phase 2: 預約系統時間範圍（2024-12-28）

**變更**：使用 PostgreSQL TSTZRANGE 儲存時間範圍

**技術決策**：
- `EXCLUDE USING GIST` 防止時段衝突
- GiST 索引優化範圍查詢

**影響表格**：`availability_slots`, `appointments`

---

### v2.8: 健康評估系統（2026-01-04）

**新增表格**：
- `health_assessments`：PAR-Q+ 健康評估問卷
- `coach_assessment_notes`：教練評估備註（私有）
- `coach_display_preferences`：教練顯示偏好設定

**技術決策**：
- 教練備註使用獨立表格（RLS 隔離）
- Upsert 模式處理備註更新

---

## 📁 Migrations 整合記錄

### 整合（2026-01-02）

**變更**：19 個檔案 → 10 個檔案（-47%）

**整合策略**：
- 合併修復檔案（4 個 → 1 個 `009_v2_fixes.sql`）
- 合併增強檔案（5 個 → 1 個 `010_v2_enhancements.sql`）

**版本劃分**：
- v1.0 核心：001-004
- v2.0 功能：005-007
- v2.x 修復：008-010+

---

## 🗑️ 已廢棄內容

### 已廢棄表格

- `equipments`：器材資料已整合到 `exercises` 表
- `joint_types`：關節類型已不再使用

### 未實作的規劃

**v2.0 屬性系統**（規劃中，未實作）：
- `attribute_categories`：屬性分類
- `attributes`：屬性標籤
- `exercise_attributes`：動作-屬性關聯
- `user_attribute_stats`：身體部位統計
- `user_exercise_stats`：單一動作統計

**狀態**：保留在規劃文檔，待未來版本實作


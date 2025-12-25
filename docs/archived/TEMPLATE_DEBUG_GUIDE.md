# 訓練模板顯示問題排查

## 問題描述
訓練模板頁面顯示「還沒有訓練模板」，但資料庫中確實有 12 個模板。

## 已驗證的事實
✅ 資料庫中有 12 個訓練模板
✅ 所有模板的 `user_id` 都正確（`d1798674-0b96-4c47-a7c7-ee20a5372a03`）
✅ 用戶已登入，email: charlie19960414@gmail.com
✅ 查詢邏輯正確（`eq('user_id', currentUserId)`）

## 可能的原因

### 1. 用戶 ID 不匹配
- **症狀**: `currentUserId` 與資料庫中的 `user_id` 不一致
- **檢查方法**: 查看終端輸出的 `userId` 值

### 2. Supabase 查詢錯誤
- **症狀**: 查詢回傳空陣列或錯誤
- **檢查方法**: 查看終端輸出的 Supabase 回應

### 3. 型別轉換錯誤
- **症狀**: `WorkoutTemplate.fromSupabase()` 拋出異常
- **檢查方法**: 查看是否有錯誤日誌

## 調試步驟

### 步驟 1: 檢查終端輸出
重新編譯並運行應用，進入訓練模板頁面，查找以下訊息：

```
[WorkoutService] 開始查詢訓練模板，userId: xxxxx
[WorkoutService] Supabase 回應: xxxxx
[WorkoutService] ✅ 成功獲取 X 個訓練模板
```

### 步驟 2: 驗證用戶 ID
如果輸出顯示 `userId: null`：
- 問題：用戶未登入或登入狀態未正確傳遞
- 解決：檢查 `AuthController` 的 `currentUser`

### 步驟 3: 檢查 Supabase 回應
如果回應為空陣列 `[]`：
- 可能原因：RLS (Row Level Security) 策略阻止查詢
- 解決：檢查 Supabase 的 RLS 策略

### 步驟 4: 清除應用緩存
```bash
flutter clean
flutter pub get
flutter run
```

## 快速修復方案

如果是 RLS 問題，可以暫時禁用 `workout_templates` 表的 RLS：

```sql
-- 在 Supabase SQL 編輯器中執行
ALTER TABLE workout_templates DISABLE ROW LEVEL SECURITY;
```

或者確保有正確的 RLS 策略：

```sql
-- 允許用戶讀取自己的模板
CREATE POLICY "Users can read own templates"
ON workout_templates
FOR SELECT
USING (auth.uid() = user_id);
```

## 下一步行動
1. 重新編譯應用
2. 進入訓練模板頁面
3. 查看終端輸出
4. 回報調試信息


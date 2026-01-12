# StrengthWise - 版本歷史

> 已完成並測試的版本詳細記錄

**最後更新**：2026-01-12

---

## v3.3: TrackingMode 統計適配 + PR 修復（2026-01-12 完成）

**功能**：
- 力量進步頁面適配：非重訓動作只顯示歷史記錄列表（不顯示趨勢圖表）
- PR DELETE 觸發器：刪除訓練計劃時重新計算 personal_records
- exerciseId 格式修復：修正異常 UUID 格式為 Firestore ID
- Migrations 整理：48 個檔案 → 32 個檔案（22 演進版 + 10 精簡版）
- Python 腳本清理：刪除 9 個一次性腳本

**技術決策**：
- `handle_workout_plan_delete()`：AFTER DELETE 觸發器重新掃描歷史找出真正 PR
- Migrations 整合：按功能模組合併，保留演進歷史

**Migration**：046-047（合併為 22_v3_pr_final_fixes.sql）

---

## v3.2: Coach Mark + TrackingMode + Web PWA（2026-01-12 完成）

**功能**：
- Coach Mark 情境式 Onboarding：11 個頁面引導（首頁、行事曆、訓練、教練/學員中心等）
- TrackingMode 擴充：8 種追蹤模式（weight_reps、time_only、distance_time 等）
- Web PWA 部署：Vercel 部署、Google OAuth Web、kIsWeb 相容處理
- setTargets 修復：訓練計畫個別組數設定正確保存

**技術決策**：
- `CurrentPageProvider`：解決 IndexedStack 頁面可見性問題
- `OnboardingService`：追蹤各功能點完成狀態（Hive 持久化）
- `CoachMarkHelper`：封裝 tutorial_coach_mark 套件
- 本地快取版本升級 v3：自動重下載含 tracking_mode 的動作資料
- pgroonga 搜尋函數更新：返回 tracking_mode 欄位

**Migration**：042-045（4 個檔案）
- 042: 傷病教練備註
- 043: 睡眠時數範圍
- 044/044b: TrackingMode 欄位 + 手動設定
- 045: 搜尋函數更新

---

## v3.1: Session Mode + 性能優化 + UX 打磨（2026-01-09 完成）

**功能**：
- Session Mode 完善：Realtime 同步、即時保存、學員唯讀、RLS 修復
- 首頁 + 行事曆 UX：快捷按鈕列、可折疊區塊、多色點點、Tab 架構
- 性能優化：Hive 快取、Isolate 解析、骨架屏、LazyIndexedStack 延遲初始化
- 預約優化：取消清理機制（觸發器）、必填原因、列表 UI 統一
- 離線提示：全局 OfflineBanner、NetworkStatusService（connectivity_plus）
- 啟動優化：SplashScreen 淡入淡出、積極導航策略

**技術決策**：
- `LazyIndexedStack`：首次只初始化當前頁面，500ms 後背景初始化其他頁面
- `SplashScreen`：PageRouteBuilder + FadeTransition 平滑過渡
- 預約取消觸發器：`cleanup_cancelled_appointment_data`、`cleanup_rejected_appointment_data`
- 全局離線 Banner：在 MaterialApp.builder 中包裝 OfflineBanner

**Migration**：034-041（8 個檔案）

---

## v3.0: 預約系統優化 + Session Mode + FCM（2026-01-06 完成）

**功能**：
- 預約系統優化：教練預約設定、學員時間偏好、衝突檢測
- Session Mode：教練上課模式頁面、課前問卷、紅綠燈狀態
- 響應式 UI：手機/平板/桌面自適應導航
- FCM 推播通知：預約提醒、課前提醒、問卷通知

**技術決策**：
- `TSTZRANGE` + GiST 索引：時段衝突檢測
- `coach_booking_settings`：教練預約設定表
- `daily_readiness`：課前問卷表（預約確認時自動創建）
- Supabase Edge Functions：推播通知觸發

**Migration**：028-033（6 個檔案）

---

## v2.9.1: 訓練 UX 優化（2026-01-05 完成）

**功能**（TRN-1 ~ TRN-7 完成）：
- 訓練狀態機：pending → in_progress → paused → completed
- 訓練時長正確記錄：實際開始/結束時間、累計秒數（不含暫停）
- 休息倒數計時器：打勾 set 後自動彈出選擇休息時長
- 權限阻止：學員無法刪除教練計畫/動作/減少組數（App 層面提前阻止）
- 訓練卡片來源標識：行事曆顯示「自主訓練」或「教練計畫」
- 移除無意義的時鐘按鈕
- 預約標籤用途釐清：納入 v3.0 Session Mode 設計

**技術決策**：
- 新增 `workout_plans` 欄位：`actual_start_time`, `actual_end_time`, `elapsed_seconds`, `training_status`
- `WorkoutExecutionDataManager` 管理狀態轉換
- `RestTimerWidget` 獨立組件（Timer.periodic + HapticFeedback）
- `canToggleCompletion()` 權限檢查：教練不能幫學員打勾、過去/未來不能打勾
- `shouldShowTimerUI()` 控制計時 UI 顯示（今天 + 非教練查看學員）

**核心檔案**：
- `migrations/027_add_training_status_fields.sql`
- `lib/controllers/workout_execution_controller.dart`
- `lib/controllers/workout_execution/workout_execution_data_manager.dart`
- `lib/views/pages/workout/execution/workout_execution_page.dart`
- `lib/views/pages/workout/execution/widgets/rest_timer_widget.dart`
- `lib/views/pages/workout/execution/widgets/exercise_card.dart`

**權限矩陣更新**：
| 操作 | 使用者（過去） | 使用者（今天） | 使用者（未來） | 教練查看學員 |
|-----|--------------|--------------|--------------|-------------|
| 打勾 set | ❌ | ✅（進行中） | ❌ | ❌ |
| 新增動作/組數 | ❌ | ✅ | ✅ | ✅ |
| 刪除自己創建的 | ❌ | ✅ | ✅ | ✅ |
| 刪除別人創建的 | ❌ | ❌ | ❌ | ❌ |
| 計時 UI | ❌ | ✅ | ❌ | ❌ |

---

## v2.9.0: 教練公開檔案 + 訓練權限系統（2026-01-04）

**功能**：
- 教練公開檔案：專業介紹、專長標籤、證照、年資、語言
- 訓練權限系統：學員不能刪除教練創建的訓練/動作
- RLS 修正：workout_plans DELETE 只允許創建者刪除

**技術決策**：
- `coaches` 表與 `users` 1:1 關聯（共用 UUID）
- `specialties` 使用 JSONB（預定義 + 自訂）
- `canDelete()` / `isViewingOthersCreatedPlan()` 權限方法
- App 層 + RLS 雙重保護

**核心檔案**：
- `migrations/025_coaches_table.sql`
- `migrations/026_fix_workout_delete_rls.sql`
- `lib/models/coach/coach_profile_model.dart`
- `lib/controllers/coach_profile_controller.dart`
- `lib/views/pages/profile/coach_profile_form_page.dart`
- `lib/views/pages/profile/coach_profile_view_page.dart`

**權限矩陣**：
| 操作 | 教練→學員（教練創建） | 學員（教練創建） | 自己（自己創建） |
|-----|---------------------|-----------------|-----------------|
| 修改參數 | ✅ | ✅ | ✅ |
| 新增動作 | ✅ | ✅ | ✅ |
| 刪除動作 | ✅ | ❌ | ✅ |
| 刪除計畫 | ✅ | ❌ | ✅ |
| 打勾 | ❌ | ✅（今天） | ✅（今天） |

---

## v2.8.4: 用戶角色與綁定優化（2026-01-04）

**功能**：
- 角色修正：啟用教練時保留學員身份（可同時擁有兩身份）
- RPC 綁定：邀請碼 + QR Code 綁定邏輯移至 DB 層
- 健康評估詳情頁：新增完整詳情頁（PAR-Q+、傷病史、生活型態）

**技術決策**：
- `bind_coach_by_invite_code` + `bind_by_qr_code` RPC 函數
- `coach_assessment_note_service` 改用單次 upsert

**核心檔案**：
- `migrations/024_binding_rpc_functions.sql`
- `lib/views/pages/profile/health_assessment_detail_page.dart`

---

## v2.8.3: PR 觸發器修復（2026-01-04）

**功能**：
- body_part 自動獲取：從 exercises/custom_exercises 表自動獲取
- 取消勾選回滾：取消 set 完成時，PR 會正確回滾到歷史最佳值
- 刪除空 PR：動作所有 sets 取消後，刪除該動作的 PR 記錄

**技術決策**：
- 支援用名稱備選查詢（當 exercise_id 找不到時）

**核心檔案**：
- `migrations/022_fix_pr_trigger_body_part.sql`
- `migrations/023_fix_updated_at.sql`

---

## v2.8.2: 文檔架構重構（2026-01-04）

**功能**：
- 文檔精簡：7 個文檔從 ~4,800 行精簡至 ~1,000 行（-79%）
- 規則模組化：新建 7 個文檔維護規則（920-980）
- 同步機制：999 加入文檔同步依賴檢查流程

**技術決策**：
- `.cursor/rules/*.mdc` 為硬性規定
- `docs/*.md` 為說明文檔

---

## v2.8.1: 教練評估備註（2026-01-04）

**功能**：
- 獨立備註表：`coach_assessment_notes`（教練間互不干擾）
- RLS 隔離：教練僅能看/改自己的備註
- UI 整合：健康評估卡片底部顯示備註輸入框

**技術決策**：
- 使用獨立表而非 JSONB 欄位（未來擴展性）

**核心檔案**：
- `migrations/021_coach_assessment_notes.sql`
- `lib/models/coach_assessment_note_model.dart`

---

## v2.8: 健康評估系統（2026-01-04）

**功能**：
- 5 步驟表單：PAR-Q+ 篩檢、傷病史、生活型態、訓練目標、緊急聯絡人
- 教練顯示偏好：自訂學員詳情頁顯示欄位（11 個可配置）
- 風險評估：低風險/中風險/高風險三級制 + 免責聲明

**技術決策**：
- 基於國際 PAR-Q+ 標準
- 使用 JSONB 儲存問卷答案

**核心檔案**：
- `migrations/016_health_assessments.sql`
- `lib/models/health_assessment/`
- `lib/views/pages/relationships/role_coach/health_assessment_page.dart`

---

## v1.0: 單機版（2024-12-24）

**功能**：
- 訓練計劃管理（創建、編輯、刪除、模板）
- 794 個專業動作資料庫（繁體中文全文搜尋）
- 專業統計系統（訓練頻率、力量進步、肌群平衡）
- 身體數據追蹤（體重、體脂、BMI）
- Google Sign-In 認證

**技術決策**：
- 使用 Supabase 取代 Firebase（PostgreSQL + RLS）
- MVVM + Clean Architecture 完全解耦
- 統計頁面使用預載入 + 智能快取

**技術亮點**：
- 應用啟動：2.5s+ → 200ms（92%+）
- 統計頁面：2-5s → 秒開（99%+）
- Cursor-based 分頁取代 Offset

---

## v2.0 Phase 1: 教練學員系統（2024-12-28）

**功能**：
- 教練邀請學員（UUID 綁定）
- 學員列表與管理（狀態：活躍/待接受/已歸檔）
- 完整 RLS 策略（雙向權限）

**技術決策**：
- `coaching_relationships` 表設計（status 狀態機）
- 5 層完全解耦架構

---

## v2.0 Phase 2: 預約系統（2024-12-28）

**功能**：
- 教練時段管理（TSTZRANGE + RRULE 週期性）
- 學員預約功能（日曆視圖）
- 狀態機（pending → confirmed → completed）

**技術決策**：
- 使用 PostgreSQL TSTZRANGE 儲存時間範圍
- GiST 排除約束（物理層防止雙重預約）
- 10 個 RLS 策略

**技術亮點**：
- `EXCLUDE USING GIST` 防止時段衝突

---

## v2.0 Phase 2.5: 時間轉換工具統一化（2024-12-29）

**功能**：
- 創建 `DateTimeUtils` 工具類（9 個方法）
- 消除 76 行重複代碼
- 修復時區偏移問題

**技術決策**：
- 統一使用 `parseIsoTimestamp()` 和 `formatToUtcIso()`
- Model 層返回本地時間，Service 層儲存 UTC

---

## v2.0 Phase 3: 視覺化筆記（2024-12-30）

**功能**：
- SOAP 專業筆記（S.O.A.P 四欄位）
- 照片上傳與 Storage（Supabase Storage + RLS 隔離）
- 學員時間偏好設定（TSTZRANGE + 優先級）
- Windows 跨平台支援

**技術決策**：
- 照片存 Supabase Storage，筆記存 PostgreSQL
- 使用 `file_picker` 跨平台支援

---

## v2.0 Phase 4A: 完整手繪板（2024-12-31）

**功能**：
- 向量繪圖系統（4 種底圖模板、4 種繪圖工具）
- 底圖保護（擦除不影響底圖）
- 模式切換（繪圖 vs 查看）

**技術決策**：
- 向量繪圖資料存 JSONB（不用 Storage，可重新編輯）

**技術亮點**：
- CustomPainter 向量繪圖
- JSONB 儲存繪圖路徑

---

## v2.0 Phase 4B-D: 教練學員整合（2025-01-01）

**功能**：
- 教練多學員統計視圖
- 教練學員頁面整合（ClientDetailPage 5 個 Tab）
- 統一行事曆系統（Layer-based Composition）

**技術決策**：
- 7 個行事曆 → 1 個 UnifiedCalendar 統一組件
- 刪除 218+ 行重複代碼

**技術亮點**：
- Layer-based Composition 架構
- 維護成本 -80%

---

## v2.1: 訓練時間範圍（2025-01-02）

**功能**：
- `training_time_range` TSTZRANGE 欄位
- 資料庫層排除約束（防止雙重預約）
- UI 支援開始/結束時間選擇

**技術決策**：
- PostgreSQL TSTZRANGE + GiST 索引
- 排除約束：`EXCLUDE USING GIST (trainee_id WITH =, training_time_range WITH &&)`

---

## v2.2: 時區統一化（2025-01-02）

**功能**：
- 全項目統一使用 `DateTimeUtils`（40+ 個文件）
- 消除 120+ 處重複代碼
- Model 層所有 DateTime 都是本地時間

**技術決策**：
- UI 層零轉換（不需要 `.toLocal()`）
- 訓練記錄按 UTC 日期分組

**技術亮點**：
- 零 `DateTime.parse()` 直接使用
- 零 `.toUtc().toIso8601String()` 直接使用

---

## v2.3: 資料庫修復與專案整理（2026-01-01）

**功能**：
- 修復 `personal_records.body_part` 欄位
- 修復統計觸發器支援布林值
- 修復 `get_available_slots()` 函數
- Python 工具腳本整理（14 → 8 個）
- Migrations 檔案整理（14 → 11 個）

**技術決策**：
- 合併修復到 `009_v2_fixes.sql`
- 合併增強到 `010_v2_enhancements.sql`

---

## v2.4: 登入驗證與個人資料（2026-01-02）

**功能**：
- 首次登入強制個人資料設定（6 個必填欄位）
- 性別隱私設定（`gender_visible` 欄位）
- Google 登入使用者可選擇性設置密碼
- 刪除帳號功能完整修復

**技術決策**：
- 使用 Supabase Auth `updateUser()` API
- 完整 Google Sign-Out（`googleSignIn.signOut()` + `supabase.auth.signOut()`）

---

## v2.5: 專業啟動頁面整合（2026-01-02）

**功能**：
- Android 全密度支援（5 種密度）
- iOS 全設備支援（11 張專業圖片）
- 平板橫屏完整支援
- 3200×3200 母版 + 600×600 安全區域

**技術決策**：
- 背景拓展技術（AI 輔助無縫延伸）
- 中心裁剪（Center Crop）策略

---

## v2.6: 已刪除帳號筆記查詢（2026-01-03）

**功能**：
- 教練/學員可查看已刪除對方的歷史筆記
- 篩選器支援已刪除用戶（👻 圖標 + 灰色文字）

**技術決策**：
- 使用 `client_name`/`coach_name` + NULL ID 查詢
- RLS 政策支援已刪除用戶的歷史筆記

**技術亮點**：
- 批量查詢避免 N+1（`getCoachClientsWithRelationship`）

---

## v2.7: UI 層結構重構（2026-01-03）

**功能**：
- 重新整理 `lib/views` 目錄結構
- 11 個頂層功能模組
- 教練學員系統 4 層結構
- 預約系統 3 層結構

**技術決策**：
- 按功能模組分類（auth, workout, relationships...）
- 120+ widgets 就近管理

---

## Migrations 整合（2026-01-02）

**變更**：
- 19 個檔案 → 10 個檔案（-47%）
- 清晰的版本劃分（v1.0 / v2.0 / v2.1+）

**技術決策**：
- 合併修復檔案（4 個 → 1 個 `009_v2_fixes.sql`）
- 合併增強檔案（5 個 → 1 個 `010_v2_enhancements.sql`）

---

## UX 重構（2025-01-02）

**變更**：
- 頁面結構優化（Tab 數量精簡）
- ClientDetailPage：5 Tab → 4 Tab
- ClientHubPage：5 Tab → 3 Tab
- CoachDetailPage：4 Tab → 3 Tab

**技術決策**：
- 移除重複功能，統一訓練視圖
- -500 行重複代碼

---

## 預約系統 UI 優化（2025-01-02）

**變更**：
- 區分「自己的預約」vs「他人的預約」
- Material 3 語意色彩
- 三種狀態清晰顯示

**技術決策**：
- PostgreSQL 函數擴展（返回 `booked_by_client_id`）


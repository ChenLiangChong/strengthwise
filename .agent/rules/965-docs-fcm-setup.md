---
description: "FCM 推播通知文檔規範：FCM_SETUP_GUIDE.md 與 Edge Functions 的維護。"
globs: "supabase/functions/**"
---

# FCM 推播通知文檔規範

## 📄 FCM_SETUP_GUIDE.md 結構

```
FCM_SETUP_GUIDE.md
├── 架構總覽（圖示）
├── Firebase 專案配置
├── 資料庫遷移
├── Secrets 設置
├── Edge Functions 部署
├── Database Webhooks 配置
├── pg_cron 定時任務
├── 測試方法
├── Flutter 端配置
└── 相關文件索引
```

---

## 📁 supabase/functions/ 目錄

| 檔案 | 用途 | 觸發方式 |
|------|------|----------|
| `push-notify/index.ts` | 預約狀態變更通知 | Database Webhook |
| `session-reminder/index.ts` | 課前 1hr 提醒 | pg_cron 定時任務 |
| `readiness-notify/index.ts` | 問卷填寫通知 | Database Webhook |

---

## 🔄 更新時機

| 變更 | 需要更新 |
|------|----------|
| 新增 Edge Function | 部署命令、相關文件索引 |
| 新增通知類型 | 通知類型表格 |
| Database Webhook 變更 | Webhook 配置區塊 |
| FCM 配置變更 | Secrets 設置區塊 |

---

## ✅ 新增 Edge Function 檢查清單

```
□ 創建 supabase/functions/xxx/index.ts
□ 更新 FCM_SETUP_GUIDE.md 相關文件索引
□ 添加 Database Webhook 或 pg_cron（如需要）
□ 部署測試：supabase functions deploy xxx
```

---

## ❌ 禁止內容

<critical>
1. FCM Server Key 明文（使用 supabase secrets）
2. Service Role Key 明文（使用環境變數）
3. 未測試的部署命令
</critical>


// ============================================================
// Supabase Edge Function: push-notify ⭐ v3.0-C
// ============================================================
// 用途：發送 FCM 推播通知（使用 HTTP v1 API）
// 觸發：Database Webhook（appointments 表變更）
// ============================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  sendFcmNotification,
  getUserTokens,
  cleanupInvalidTokens,
} from "../_shared/fcm.ts";

// CORS 標頭
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// 通知類型
type NotificationType =
  | "new_appointment"
  | "appointment_confirmed"
  | "appointment_rejected"
  | "appointment_cancelled"
  | "session_reminder"
  | "readiness_submitted";

// 通知內容生成
function getNotificationContent(
  type: NotificationType,
  data: Record<string, unknown>
): { title: string; body: string } {
  switch (type) {
    case "new_appointment":
      return {
        title: "📅 新預約請求",
        body: `學員預約了 ${data.date} ${data.time} 的課程`,
      };
    case "appointment_confirmed":
      return {
        title: "✅ 預約已確認",
        body: `${data.coachName} 教練已確認您的預約`,
      };
    case "appointment_rejected":
      return {
        title: "❌ 預約被拒絕",
        body: `${data.coachName} 教練無法在此時段上課`,
      };
    case "appointment_cancelled":
      return {
        title: "🚫 預約已取消",
        body: `${data.cancelledBy} 取消了 ${data.date} 的課程`,
      };
    case "session_reminder":
      return {
        title: "⏰ 課程提醒",
        body: `1 小時後有課程，請準備好！`,
      };
    case "readiness_submitted":
      return {
        title: "📋 學員已填寫問卷",
        body: `${data.clientName} 已完成課前問卷`,
      };
    default:
      return {
        title: "StrengthWise",
        body: "您有新的通知",
      };
  }
}

// 主處理函數
serve(async (req) => {
  // 處理 CORS preflight
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // 獲取環境變數
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    // 創建 Supabase 客戶端（使用 service role）
    const supabase = createClient(supabaseUrl, supabaseKey);

    // 解析請求
    const payload = await req.json();
    console.log("[push-notify] Webhook payload:", JSON.stringify(payload, null, 2));

    const { type, table, record, old_record } = payload;

    // 只處理 appointments 表的變更
    if (table !== "appointments") {
      return new Response(
        JSON.stringify({ message: "Not an appointments event" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    let notificationType: NotificationType | null = null;
    let targetUserId: string | null = null;
    let notificationData: Record<string, unknown> = {};

    // 根據事件類型決定通知
    if (type === "INSERT" && record.status === "requested") {
      // 新預約 → 通知教練
      notificationType = "new_appointment";
      targetUserId = record.coach_id;

      // 解析時間
      const timeRange = record.time_range;
      const startMatch = timeRange?.match(/\["([^"]+)"/);
      const startTime = startMatch ? new Date(startMatch[1]) : new Date();

      notificationData = {
        date: `${startTime.getMonth() + 1}/${startTime.getDate()}`,
        time: `${startTime.getHours()}:${startTime.getMinutes().toString().padStart(2, "0")}`,
        appointmentId: record.id,
      };
    } else if (type === "UPDATE") {
      const oldStatus = old_record?.status;
      const newStatus = record.status;

      if (oldStatus === "requested" && newStatus === "confirmed") {
        // 確認預約 → 通知學員
        notificationType = "appointment_confirmed";
        targetUserId = record.client_id;

        // 獲取教練名稱
        const { data: coach } = await supabase
          .from("users")
          .select("display_name")
          .eq("id", record.coach_id)
          .single();

        notificationData = {
          coachName: coach?.display_name || "教練",
          appointmentId: record.id,
        };
      } else if (oldStatus === "requested" && newStatus === "rejected") {
        // 拒絕預約 → 通知學員
        notificationType = "appointment_rejected";
        targetUserId = record.client_id;

        const { data: coach } = await supabase
          .from("users")
          .select("display_name")
          .eq("id", record.coach_id)
          .single();

        notificationData = {
          coachName: coach?.display_name || "教練",
          appointmentId: record.id,
        };
      } else if (newStatus === "cancelled") {
        // 取消預約 → 通知對方
        const cancelledBy = record.cancelled_by;

        // 通知對方
        targetUserId =
          cancelledBy === record.coach_id
            ? record.client_id
            : record.coach_id;

        const { data: canceller } = await supabase
          .from("users")
          .select("display_name")
          .eq("id", cancelledBy)
          .single();

        // 解析時間
        const timeRange = record.time_range;
        const startMatch = timeRange?.match(/\["([^"]+)"/);
        const startTime = startMatch ? new Date(startMatch[1]) : new Date();

        notificationType = "appointment_cancelled";
        notificationData = {
          cancelledBy: canceller?.display_name || "用戶",
          date: `${startTime.getMonth() + 1}/${startTime.getDate()}`,
          appointmentId: record.id,
        };
      }
    }

    // 沒有需要發送的通知
    if (!notificationType || !targetUserId) {
      return new Response(
        JSON.stringify({ message: "No notification needed" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 獲取目標用戶的 FCM Tokens（從 user_devices 表）
    const tokens = await getUserTokens(supabase, targetUserId);

    if (tokens.length === 0) {
      console.log("[push-notify] No FCM tokens for user:", targetUserId);
      return new Response(
        JSON.stringify({ message: "No FCM tokens for target user" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 生成通知內容
    const { title, body } = getNotificationContent(
      notificationType,
      notificationData
    );

    // 發送 FCM 通知（HTTP v1 API）
    const result = await sendFcmNotification(tokens, title, body, {
      type: notificationType,
      appointmentId: record.id,
    });

    // 清理無效 Tokens
    if (result.invalidTokens.length > 0) {
      await cleanupInvalidTokens(supabase, result.invalidTokens);
    }

    console.log("[push-notify] Notification sent:", result);

    return new Response(
      JSON.stringify({
        success: result.success > 0,
        sent: result.success,
        failed: result.failure,
        type: notificationType,
        targetUserId,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[push-notify] Error:", error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

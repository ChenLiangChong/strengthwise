// ============================================================
// Supabase Edge Function: session-reminder ⭐ v3.0-C
// ============================================================
// 用途：課前 1 小時提醒（雙方）+ 課前問卷提醒
// 觸發：Supabase pg_cron 定時任務（每 5 分鐘）
// ============================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  sendFcmNotification,
  getUserTokens,
  cleanupInvalidTokens,
} from "../_shared/fcm.ts";

// 安全標頭（內部 pg_cron 觸發，不需 CORS 開放）
const corsHeaders = {
  "Access-Control-Allow-Origin": "",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Strict-Transport-Security": "max-age=63072000; includeSubDomains",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseKey);

    const now = new Date();
    const oneHourLater = new Date(now.getTime() + 60 * 60 * 1000);

    console.log(
      `[session-reminder] 檢查 ${now.toISOString()} 到 ${oneHourLater.toISOString()} 的課程`
    );

    // 查詢即將開始的課程（使用 RPC 函數更可靠）
    // 由於 TSTZRANGE 的複雜性，使用原始 SQL 查詢
    const { data: appointments, error: appointmentError } = await supabase
      .from("appointments")
      .select(`
        id,
        coach_id,
        client_id,
        time_range,
        status
      `)
      .eq("status", "confirmed");

    if (appointmentError) {
      console.error("[session-reminder] 查詢預約失敗:", appointmentError);
      throw appointmentError;
    }

    // 過濾即將開始的課程（1 小時內）
    const upcomingAppointments = (appointments || []).filter((apt) => {
      const timeRange = apt.time_range;
      const startMatch = timeRange?.match(/\["([^"]+)"/);
      if (!startMatch) return false;

      const startTime = new Date(startMatch[1]);
      const minutesUntilStart = (startTime.getTime() - now.getTime()) / 60000;

      // 只在 55-65 分鐘內發送（避免重複發送）
      return minutesUntilStart >= 55 && minutesUntilStart <= 65;
    });

    console.log(
      `[session-reminder] 找到 ${upcomingAppointments.length} 個即將開始的課程`
    );

    const notifications: {
      userId: string;
      title: string;
      body: string;
      data: Record<string, string>;
    }[] = [];

    // 為每個課程生成提醒
    for (const apt of upcomingAppointments) {
      // 解析開始時間
      const timeRange = apt.time_range;
      const startMatch = timeRange?.match(/\["([^"]+)"/);
      const startTime = startMatch ? new Date(startMatch[1]) : null;

      if (!startTime) continue;

      const timeStr = `${startTime.getHours()}:${startTime
        .getMinutes()
        .toString()
        .padStart(2, "0")}`;

      // 通知教練
      notifications.push({
        userId: apt.coach_id,
        title: "⏰ 課程即將開始",
        body: `${timeStr} 有課程，請準備好！`,
        data: {
          type: "session_reminder",
          appointmentId: apt.id,
        },
      });

      // 檢查學員是否已填寫問卷
      const { data: readiness } = await supabase
        .from("daily_readiness")
        .select("id, readiness_score")
        .eq("appointment_id", apt.id)
        .eq("user_id", apt.client_id)
        .maybeSingle();

      if (readiness?.readiness_score !== null) {
        // 已填寫，只發課程提醒
        notifications.push({
          userId: apt.client_id,
          title: "⏰ 課程即將開始",
          body: `${timeStr} 有課程，請準備好！`,
          data: {
            type: "session_reminder",
            appointmentId: apt.id,
          },
        });
      } else {
        // 未填寫，提醒填寫問卷
        notifications.push({
          userId: apt.client_id,
          title: "📋 請填寫課前問卷",
          body: `${timeStr} 的課程即將開始，請先填寫課前問卷讓教練了解您的狀態`,
          data: {
            type: "readiness_reminder",
            appointmentId: apt.id,
          },
        });
      }
    }

    console.log(
      `[session-reminder] 準備發送 ${notifications.length} 個通知`
    );

    // 發送通知
    let successCount = 0;
    let invalidTokens: string[] = [];

    for (const notification of notifications) {
      const tokens = await getUserTokens(supabase, notification.userId);

      if (tokens.length > 0) {
        const result = await sendFcmNotification(
          tokens,
          notification.title,
          notification.body,
          notification.data
        );

        successCount += result.success;
        invalidTokens = [...invalidTokens, ...result.invalidTokens];
      }
    }

    // 批量清理無效 Tokens
    if (invalidTokens.length > 0) {
      await cleanupInvalidTokens(supabase, invalidTokens);
    }

    console.log(
      `[session-reminder] 成功發送 ${successCount}/${notifications.length} 個通知`
    );

    return new Response(
      JSON.stringify({
        success: true,
        appointmentsChecked: upcomingAppointments.length,
        notificationsSent: successCount,
        totalNotifications: notifications.length,
        invalidTokensCleaned: invalidTokens.length,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[session-reminder] Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});


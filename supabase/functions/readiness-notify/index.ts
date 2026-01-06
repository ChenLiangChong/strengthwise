// ============================================================
// Supabase Edge Function: readiness-notify ⭐ v3.0-C
// ============================================================
// 用途：學員填寫課前問卷後通知教練
// 觸發：Database Webhook（daily_readiness 表 UPDATE）
// ============================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  sendFcmNotification,
  getUserTokens,
  cleanupInvalidTokens,
} from "../_shared/fcm.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// 紅綠燈轉文字
function getTrafficLightText(trafficLight: string): string {
  switch (trafficLight?.toUpperCase()) {
    case "GREEN":
      return "🟢 狀態良好";
    case "AMBER":
      return "🟡 狀態一般";
    case "RED":
      return "🔴 需要注意";
    default:
      return "";
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

    const supabase = createClient(supabaseUrl, supabaseKey);

    // 解析請求
    const payload = await req.json();
    console.log(
      "[readiness-notify] Webhook payload:",
      JSON.stringify(payload, null, 2)
    );

    const { type, table, record, old_record } = payload;

    // 只處理 daily_readiness 表的更新
    if (table !== "daily_readiness") {
      return new Response(
        JSON.stringify({ message: "Not a daily_readiness event" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 檢查是否是新填寫（readiness_score 從 NULL 變成有值）
    const wasSubmitted = old_record?.readiness_score !== null;
    const isNowSubmitted = record?.readiness_score !== null;

    if (wasSubmitted || !isNowSubmitted) {
      return new Response(
        JSON.stringify({ message: "Not a new submission" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    console.log(
      `[readiness-notify] 學員 ${record.user_id} 已填寫課前問卷`
    );

    // 獲取關聯的預約資訊
    const { data: appointment, error: aptError } = await supabase
      .from("appointments")
      .select("id, coach_id, client_id, time_range")
      .eq("id", record.appointment_id)
      .single();

    if (aptError || !appointment) {
      console.error("[readiness-notify] 找不到關聯的預約:", aptError);
      return new Response(
        JSON.stringify({ message: "Appointment not found" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 獲取學員名稱
    const { data: client } = await supabase
      .from("users")
      .select("display_name, email")
      .eq("id", record.user_id)
      .single();

    const clientName = client?.display_name || client?.email || "學員";

    // 獲取教練的 FCM Tokens
    const tokens = await getUserTokens(supabase, appointment.coach_id);

    if (tokens.length === 0) {
      console.log("[readiness-notify] 教練沒有 FCM Token");
      return new Response(
        JSON.stringify({ message: "Coach has no FCM tokens" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 發送通知
    const trafficLight = record.traffic_light || "AMBER";
    const trafficLightText = getTrafficLightText(trafficLight);

    const result = await sendFcmNotification(
      tokens,
      "📋 學員已填寫課前問卷",
      `${clientName} 已完成課前問卷 ${trafficLightText}`,
      {
        type: "readiness_submitted",
        appointmentId: record.appointment_id,
        clientId: record.user_id,
        trafficLight: trafficLight,
      }
    );

    // 清理無效 Tokens
    if (result.invalidTokens.length > 0) {
      await cleanupInvalidTokens(supabase, result.invalidTokens);
    }

    console.log(
      `[readiness-notify] 通知發送${result.success > 0 ? "成功" : "失敗"}`
    );

    return new Response(
      JSON.stringify({
        success: result.success > 0,
        clientName,
        trafficLight,
        coachId: appointment.coach_id,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[readiness-notify] Error:", error);
    return new Response(
      JSON.stringify({ error: String(error) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

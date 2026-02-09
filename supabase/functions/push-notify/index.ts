// ============================================================
// Supabase Edge Function: push-notify ⭐ v3.9
// ============================================================
// 用途：發送 FCM 推播通知（使用 HTTP v1 API）
// 觸發：Database Webhook（多表變更）
// 支援：appointments, availability_slots, client_availability, workout_plans
// ============================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import {
  sendFcmNotification,
  getUserTokens,
  cleanupInvalidTokens,
} from "../_shared/fcm.ts";
import {
  generateNotificationContent,
  generateRoute,
} from "../_shared/notification_types.ts";

// 安全標頭（內部 webhook，不需 CORS 開放）
const corsHeaders = {
  "Access-Control-Allow-Origin": "",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Strict-Transport-Security": "max-age=63072000; includeSubDomains",
};

// 通知處理結果
interface NotificationResult {
  type: string | null;
  targetUserId: string | null;
  data: Record<string, unknown>;
}

// ============================================================
// 表格處理器
// ============================================================

/**
 * 處理 appointments 表變更
 */
async function handleAppointments(
  supabase: ReturnType<typeof createClient>,
  type: string,
  record: Record<string, unknown>,
  oldRecord: Record<string, unknown> | null
): Promise<NotificationResult> {
  const result: NotificationResult = { type: null, targetUserId: null, data: {} };

  // 解析時間
  const timeRange = record.time_range as string;
  const startMatch = timeRange?.match(/\["([^"]+)"/);
  const startTime = startMatch ? new Date(startMatch[1]) : new Date();
  const dateStr = `${startTime.getMonth() + 1}/${startTime.getDate()}`;
  const timeStr = `${startTime.getHours()}:${startTime.getMinutes().toString().padStart(2, "0")}`;

  if (type === "INSERT" && record.status === "requested") {
    // 新預約 → 通知教練
    result.type = "new_appointment";
    result.targetUserId = record.coach_id as string;
    result.data = {
      date: dateStr,
      time: timeStr,
      appointmentId: record.id,
    };
  } else if (type === "UPDATE") {
    const oldStatus = oldRecord?.status;
    const newStatus = record.status;

    if (oldStatus === "requested" && newStatus === "confirmed") {
      // 確認預約 → 通知學員
      result.type = "appointment_confirmed";
      result.targetUserId = record.client_id as string;

      const { data: coach } = await supabase
        .from("users")
        .select("display_name")
        .eq("id", record.coach_id)
        .single();

      result.data = {
        coachName: coach?.display_name || "教練",
        appointmentId: record.id,
      };
    } else if (oldStatus === "requested" && newStatus === "rejected") {
      // 拒絕預約 → 通知學員
      result.type = "appointment_rejected";
      result.targetUserId = record.client_id as string;

      const { data: coach } = await supabase
        .from("users")
        .select("display_name")
        .eq("id", record.coach_id)
        .single();

      result.data = {
        coachName: coach?.display_name || "教練",
        appointmentId: record.id,
      };
    } else if (newStatus === "cancelled") {
      // 取消預約 → 通知對方
      const cancelledById = record.cancelled_by as string;
      const isCoachCancelled = cancelledById === record.coach_id;
      
      result.targetUserId = isCoachCancelled
        ? (record.client_id as string)   // 教練取消 → 通知學員
        : (record.coach_id as string);   // 學員取消 → 通知教練

      const { data: canceller } = await supabase
        .from("users")
        .select("display_name")
        .eq("id", cancelledById)
        .single();

      result.type = "appointment_cancelled";
      result.data = {
        cancelledBy: canceller?.display_name || "用戶",
        // ⭐ v3.9: 添加角色標記，客戶端用於判斷跳轉目標
        cancelled_by: isCoachCancelled ? "coach" : "client",
        date: dateStr,
        appointmentId: record.id,
      };
    }
  }

  return result;
}

/**
 * 處理 availability_slots 表變更（教練時段）
 */
async function handleAvailabilitySlots(
  supabase: ReturnType<typeof createClient>,
  type: string,
  record: Record<string, unknown>
): Promise<NotificationResult[]> {
  const results: NotificationResult[] = [];
  const coachId = record.coach_id as string;

  // 獲取教練名稱
  const { data: coach } = await supabase
    .from("users")
    .select("display_name")
    .eq("id", coachId)
    .single();

  const coachName = coach?.display_name || "教練";

  // 獲取該教練的所有活躍學員
  const { data: relationships } = await supabase
    .from("coaching_relationships")
    .select("client_id")
    .eq("coach_id", coachId)
    .eq("status", "active");

  if (!relationships || relationships.length === 0) {
    console.log("[push-notify] No active clients for coach:", coachId);
    return results;
  }

  // 根據事件類型決定通知類型
  // ⭐ v3.9: DELETE 不推播
  let notificationType: string;
  switch (type) {
    case "INSERT":
      notificationType = "coach_slot_created";
      break;
    case "UPDATE":
      notificationType = "coach_slot_updated";
      break;
    case "DELETE":
      // 刪除不推播
      console.log("[push-notify] Skipping DELETE for availability_slots");
      return results;
    default:
      return results;
  }

  // 為每個學員創建通知
  for (const rel of relationships) {
    results.push({
      type: notificationType,
      targetUserId: rel.client_id,
      data: {
        coachId,
        coachName,
        slotId: record.id,
      },
    });
  }

  return results;
}

/**
 * 處理 client_availability 表變更（學員可訓練時間）
 */
async function handleClientAvailability(
  supabase: ReturnType<typeof createClient>,
  type: string,
  record: Record<string, unknown>
): Promise<NotificationResult[]> {
  const results: NotificationResult[] = [];
  const clientId = record.client_id as string;

  // 獲取學員名稱
  const { data: client } = await supabase
    .from("users")
    .select("display_name")
    .eq("id", clientId)
    .single();

  const clientName = client?.display_name || "學員";

  // 獲取該學員的所有活躍教練
  const { data: relationships } = await supabase
    .from("coaching_relationships")
    .select("coach_id")
    .eq("client_id", clientId)
    .eq("status", "active");

  if (!relationships || relationships.length === 0) {
    console.log("[push-notify] No active coaches for client:", clientId);
    return results;
  }

  // 根據事件類型決定通知類型
  // ⭐ v3.9: DELETE 不推播
  let notificationType: string;
  switch (type) {
    case "INSERT":
      notificationType = "client_availability_created";
      break;
    case "UPDATE":
      notificationType = "client_availability_updated";
      break;
    case "DELETE":
      // 刪除不推播
      console.log("[push-notify] Skipping DELETE for client_availability");
      return results;
    default:
      return results;
  }

  // 為每個教練創建通知
  for (const rel of relationships) {
    results.push({
      type: notificationType,
      targetUserId: rel.coach_id,
      data: {
        clientId,
        clientName,
        availabilityId: record.id,
      },
    });
  }

  return results;
}

/**
 * 處理 workout_plans 表變更（訓練計畫）
 * 
 * 只有教練為學員創建/更新時才推播給學員
 * 學員自己創建的不推播（creator_id = trainee_id）
 */
async function handleWorkoutPlans(
  supabase: ReturnType<typeof createClient>,
  type: string,
  record: Record<string, unknown>,
  oldRecord: Record<string, unknown> | null
): Promise<NotificationResult> {
  const result: NotificationResult = { type: null, targetUserId: null, data: {} };

  const traineeId = record.trainee_id as string;
  const creatorId = record.creator_id as string;

  // 自己創建的訓練計畫不推播
  if (!traineeId || !creatorId || traineeId === creatorId) {
    console.log("[push-notify] Skipping workout_plan: self-created");
    return result;
  }

  // 獲取教練名稱
  const { data: coach } = await supabase
    .from("users")
    .select("display_name")
    .eq("id", creatorId)
    .single();

  const coachName = coach?.display_name || "教練";

  // 解析日期
  const scheduledDate = record.scheduled_date as string;
  const date = scheduledDate 
    ? new Date(scheduledDate).toLocaleDateString("zh-TW", { month: "numeric", day: "numeric" })
    : "";

  // 根據事件類型決定通知類型（只處理 INSERT 和 DELETE）
  switch (type) {
    case "INSERT":
      result.type = "workout_plan_created";
      result.targetUserId = traineeId;
      result.data = {
        coachName,
        date,
        workoutId: record.id,
      };
      break;

    case "UPDATE":
      // 更新不推播（Realtime 處理）
      console.log("[push-notify] Skipping UPDATE for workout_plans");
      break;

    case "DELETE":
      // 刪除訓練計畫 → 通知學員
      // 注意：DELETE 時 record 為空，需要用 oldRecord
      const oldTraineeId = oldRecord?.trainee_id as string;
      const oldCreatorId = oldRecord?.creator_id as string;
      
      // 自己刪除自己的不推播
      if (!oldTraineeId || !oldCreatorId || oldTraineeId === oldCreatorId) {
        console.log("[push-notify] Skipping DELETE: self-created workout");
        break;
      }

      // 獲取刪除者（教練）名稱
      const { data: deletor } = await supabase
        .from("users")
        .select("display_name")
        .eq("id", oldCreatorId)
        .single();

      const oldScheduledDate = oldRecord?.scheduled_date as string;
      const oldDate = oldScheduledDate 
        ? new Date(oldScheduledDate).toLocaleDateString("zh-TW", { month: "numeric", day: "numeric" })
        : "";

      result.type = "workout_plan_deleted";
      result.targetUserId = oldTraineeId;
      result.data = {
        coachName: deletor?.display_name || "教練",
        date: oldDate,
        workoutId: oldRecord?.id,
      };
      break;
  }

  return result;
}

// ============================================================
// 主處理函數
// ============================================================

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
    console.log("[push-notify] Processing:", { type: payload.type, table: payload.table, recordId: payload.record?.id });

    const { type, table, record, old_record } = payload;

    // 根據表名分發處理
    let notifications: NotificationResult[] = [];

    switch (table) {
      case "appointments":
        const appointmentResult = await handleAppointments(
          supabase,
          type,
          record,
          old_record
        );
        if (appointmentResult.type) {
          notifications.push(appointmentResult);
        }
        break;

      case "availability_slots":
        // 處理所有事件：INSERT, UPDATE, DELETE
        notifications = await handleAvailabilitySlots(supabase, type, record);
        break;

      case "client_availability":
        // 處理所有事件：INSERT, UPDATE, DELETE
        notifications = await handleClientAvailability(supabase, type, record);
        break;

      case "workout_plans":
        // 處理教練為學員創建/更新訓練計畫
        const workoutResult = await handleWorkoutPlans(
          supabase,
          type,
          record,
          old_record
        );
        if (workoutResult.type) {
          notifications.push(workoutResult);
        }
        break;

      default:
        return new Response(
          JSON.stringify({ message: `Unsupported table: ${table}` }),
          { headers: { ...corsHeaders, "Content-Type": "application/json" } }
        );
    }

    // 沒有需要發送的通知
    if (notifications.length === 0) {
      return new Response(
        JSON.stringify({ message: "No notifications to send" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // 發送所有通知
    let totalSuccess = 0;
    let totalFailure = 0;
    const allInvalidTokens: string[] = [];

    for (const notification of notifications) {
      if (!notification.type || !notification.targetUserId) continue;

      // 獲取目標用戶的 FCM Tokens
      const tokens = await getUserTokens(supabase, notification.targetUserId);

      if (tokens.length === 0) {
        console.log("[push-notify] No FCM tokens for user:", notification.targetUserId);
        continue;
      }

      // 生成通知內容
      const content = generateNotificationContent(
        notification.type,
        notification.data
      );

      if (!content) {
        console.log("[push-notify] Unknown notification type:", notification.type);
        continue;
      }

      // 生成跳轉路由
      const route = generateRoute(notification.type, notification.data);

      // 發送 FCM 通知
      const result = await sendFcmNotification(tokens, content.title, content.body, {
        type: notification.type,
        route: route || "",
        ...Object.fromEntries(
          Object.entries(notification.data).map(([k, v]) => [k, String(v)])
        ),
      });

      totalSuccess += result.success;
      totalFailure += result.failure;
      allInvalidTokens.push(...result.invalidTokens);
    }

    // 清理無效 Tokens
    if (allInvalidTokens.length > 0) {
      await cleanupInvalidTokens(supabase, allInvalidTokens);
    }

    console.log("[push-notify] Summary:", {
      notifications: notifications.length,
      success: totalSuccess,
      failure: totalFailure,
    });

    return new Response(
      JSON.stringify({
        success: totalSuccess > 0,
        notifications: notifications.length,
        sent: totalSuccess,
        failed: totalFailure,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (error) {
    console.error("[push-notify] Error:", error);
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  }
});

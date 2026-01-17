// ============================================================
// 通知類型統一定義 ⭐ v3.9
// ============================================================
// 集中管理所有通知類型，前後端共用
// 新增通知類型只需在此添加，無需修改多處代碼
// ============================================================

/**
 * 通知類型定義
 */
export interface NotificationTypeConfig {
  /** 通知標題模板 */
  title: string;
  /** 通知內容模板（支援變數替換：{varName}） */
  bodyTemplate: string;
  /** 點擊後跳轉的路由（支援變數替換） */
  route: string;
  /** 通知分類（用於未來的通知偏好設定） */
  category: "appointment" | "availability" | "relationship" | "training" | "general";
}

/**
 * 所有通知類型註冊表
 * 
 * 命名規範：snake_case（與 FCM payload 一致）
 * 
 * ⭐ v3.9 更新：
 * - 關係相關、課程筆記：不推播
 * - 時段刪除：不推播
 * - 課程提醒：包含問卷提示
 */
export const NOTIFICATION_TYPES: Record<string, NotificationTypeConfig> = {
  // ==================== 預約相關 ====================
  new_appointment: {
    title: "📅 新預約請求",
    bodyTemplate: "學員預約了 {date} {time} 的課程",
    route: "/home",
    category: "appointment",
  },
  appointment_confirmed: {
    title: "✅ 預約已確認",
    bodyTemplate: "{coachName} 教練已確認您的預約",
    route: "/home",
    category: "appointment",
  },
  appointment_rejected: {
    title: "❌ 預約被拒絕",
    bodyTemplate: "{coachName} 教練無法在此時段上課",
    route: "/client-hub",
    category: "appointment",
  },
  appointment_cancelled: {
    title: "🚫 預約已取消",
    bodyTemplate: "{cancelledBy} 取消了 {date} 的課程",
    route: "/hub", // 根據 cancelled_by 決定跳轉
    category: "appointment",
  },
  // ⭐ v3.9: 課程提醒（通知雙方，學員版包含問卷提示）
  session_reminder: {
    title: "⏰ 課程提醒",
    bodyTemplate: "1 小時後有課程，請準備好！",
    route: "/home",
    category: "appointment",
  },
  session_reminder_client: {
    title: "⏰ 課程提醒",
    bodyTemplate: "1 小時後有課程，請先填寫課前問卷！",
    route: "/home",
    category: "appointment",
  },

  // ==================== 課前問卷 ====================
  readiness_submitted: {
    title: "📋 學員已填寫問卷",
    bodyTemplate: "{clientName} 已完成課前問卷",
    route: "/home",
    category: "training",
  },

  // ==================== 時段相關 ====================
  // 教練新增/修改時段 → 學員收到
  coach_slot_created: {
    title: "📆 教練新增可預約時段",
    bodyTemplate: "{coachName} 教練新增了可預約時段",
    route: "/booking/0", // BookingPage Tab 0
    category: "availability",
  },
  coach_slot_updated: {
    title: "✏️ 教練修改時段",
    bodyTemplate: "{coachName} 教練修改了可預約時段",
    route: "/booking/0",
    category: "availability",
  },
  // 學員新增/修改時段 → 教練收到
  client_availability_created: {
    title: "🕐 學員新增可訓練時間",
    bodyTemplate: "{clientName} 新增了可訓練時間偏好",
    route: "/booking/1", // BookingPage Tab 1
    category: "availability",
  },
  client_availability_updated: {
    title: "🔄 學員更新可訓練時間",
    bodyTemplate: "{clientName} 更新了可訓練時間偏好",
    route: "/booking/1",
    category: "availability",
  },
  // 刪除相關：不推播（已從列表移除）

  // ==================== 訓練計畫相關 ====================
  // 教練為學員創建訓練計畫 → 學員收到
  workout_plan_created: {
    title: "🏋️ 教練新增訓練計畫",
    bodyTemplate: "{coachName} 教練為您安排了 {date} 的訓練",
    route: "/booking/0", // 學員的行事曆
    category: "training",
  },
  // 教練刪除訓練計畫 → 學員收到
  workout_plan_deleted: {
    title: "🗑️ 訓練計畫已刪除",
    bodyTemplate: "{coachName} 教練刪除了您 {date} 的訓練計畫",
    route: "/booking/0",
    category: "training",
  },
  // 更新：不推播（Realtime 處理）
};

/**
 * 獲取通知配置
 */
export function getNotificationConfig(type: string): NotificationTypeConfig | null {
  return NOTIFICATION_TYPES[type] || null;
}

/**
 * 替換模板變數
 * 
 * @example
 * replaceTemplateVars("Hello {name}!", { name: "World" })
 * // => "Hello World!"
 */
export function replaceTemplateVars(
  template: string,
  vars: Record<string, unknown>
): string {
  return template.replace(/\{(\w+)\}/g, (match, key) => {
    return vars[key] !== undefined ? String(vars[key]) : match;
  });
}

/**
 * 生成通知內容
 */
export function generateNotificationContent(
  type: string,
  data: Record<string, unknown>
): { title: string; body: string } | null {
  const config = getNotificationConfig(type);
  if (!config) return null;

  return {
    title: config.title,
    body: replaceTemplateVars(config.bodyTemplate, data),
  };
}

/**
 * 生成跳轉路由
 */
export function generateRoute(
  type: string,
  data: Record<string, unknown>
): string | null {
  const config = getNotificationConfig(type);
  if (!config) return null;

  return replaceTemplateVars(config.route, data);
}

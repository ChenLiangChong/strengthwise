// ============================================================
// FCM HTTP v1 API 共用模組 ⭐ v3.0-C
// ============================================================
// 使用 OAuth 2.0 Service Account 驗證
// 文檔：https://firebase.google.com/docs/cloud-messaging/migrate-v1
// ============================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// Service Account 配置（從環境變數讀取）
interface ServiceAccount {
  project_id: string;
  private_key: string;
  client_email: string;
}

// FCM 訊息結構
interface FcmMessage {
  token: string;
  notification?: {
    title: string;
    body: string;
  };
  data?: Record<string, string>;
  android?: {
    priority?: "high" | "normal";
    notification?: {
      click_action?: string;
      sound?: string;
    };
  };
}

// Token 快取（避免頻繁生成）
let cachedAccessToken: string | null = null;
let tokenExpiry: number = 0;

/**
 * 將 PEM 格式私鑰轉換為 CryptoKey
 */
async function importPrivateKey(pem: string): Promise<CryptoKey> {
  // 移除 PEM 標頭/尾和換行
  const pemContents = pem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\n/g, "");

  // Base64 解碼
  const binaryString = atob(pemContents);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }

  // 匯入為 RSASSA-PKCS1-v1_5 密鑰
  return await crypto.subtle.importKey(
    "pkcs8",
    bytes,
    {
      name: "RSASSA-PKCS1-v1_5",
      hash: "SHA-256",
    },
    false,
    ["sign"]
  );
}

/**
 * Base64URL 編碼
 */
function base64UrlEncode(data: Uint8Array | string): string {
  const str = typeof data === "string" ? data : new TextDecoder().decode(data);
  const base64 = btoa(str);
  return base64.replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

/**
 * 生成 JWT Token
 */
async function generateJwt(serviceAccount: ServiceAccount): Promise<string> {
  const header = {
    alg: "RS256",
    typ: "JWT",
  };

  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: serviceAccount.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600, // 1 小時有效
  };

  const headerB64 = base64UrlEncode(JSON.stringify(header));
  const payloadB64 = base64UrlEncode(JSON.stringify(payload));
  const signatureInput = `${headerB64}.${payloadB64}`;

  // 簽名
  const key = await importPrivateKey(serviceAccount.private_key);
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(signatureInput)
  );

  const signatureB64 = base64UrlEncode(
    String.fromCharCode(...new Uint8Array(signature))
  );

  return `${headerB64}.${payloadB64}.${signatureB64}`;
}

/**
 * 獲取 OAuth 2.0 Access Token
 */
async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  // 檢查快取
  const now = Date.now();
  if (cachedAccessToken && tokenExpiry > now + 60000) {
    return cachedAccessToken;
  }

  // 生成 JWT
  const jwt = await generateJwt(serviceAccount);

  // 交換 Access Token
  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  if (!response.ok) {
    const error = await response.text();
    throw new Error(`Failed to get access token: ${error}`);
  }

  const data = await response.json();
  cachedAccessToken = data.access_token;
  tokenExpiry = now + (data.expires_in - 60) * 1000; // 提前 60 秒過期

  return cachedAccessToken!;
}

/**
 * 從環境變數獲取 Service Account
 */
function getServiceAccount(): ServiceAccount {
  const projectId = Deno.env.get("FCM_PROJECT_ID");
  const privateKey = Deno.env.get("FCM_PRIVATE_KEY");
  const clientEmail = Deno.env.get("FCM_CLIENT_EMAIL");

  if (!projectId || !privateKey || !clientEmail) {
    throw new Error(
      "Missing FCM configuration. Required: FCM_PROJECT_ID, FCM_PRIVATE_KEY, FCM_CLIENT_EMAIL"
    );
  }

  return {
    project_id: projectId,
    private_key: privateKey.replace(/\\n/g, "\n"), // 處理轉義的換行
    client_email: clientEmail,
  };
}

/**
 * 發送 FCM 通知（HTTP v1 API）
 */
export async function sendFcmNotification(
  tokens: string[],
  title: string,
  body: string,
  data: Record<string, string> = {}
): Promise<{
  success: number;
  failure: number;
  invalidTokens: string[];
}> {
  if (tokens.length === 0) {
    return { success: 0, failure: 0, invalidTokens: [] };
  }

  const serviceAccount = getServiceAccount();
  const accessToken = await getAccessToken(serviceAccount);

  const results = {
    success: 0,
    failure: 0,
    invalidTokens: [] as string[],
  };

  // HTTP v1 API 需要逐一發送（或使用 Topic）
  const promises = tokens.map(async (token) => {
    try {
      const message: FcmMessage = {
        token,
        notification: { title, body },
        data: {
          ...data,
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            click_action: "FLUTTER_NOTIFICATION_CLICK",
            sound: "default",
          },
        },
      };

      const response = await fetch(
        `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
        {
          method: "POST",
          headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ message }),
        }
      );

      if (response.ok) {
        results.success++;
      } else {
        const error = await response.json();
        console.error(`FCM Error for token ${token.substring(0, 20)}:`, error);

        // 檢查是否是無效 Token
        if (
          error.error?.details?.some(
            (d: { errorCode?: string }) =>
              d.errorCode === "UNREGISTERED" || d.errorCode === "INVALID_ARGUMENT"
          )
        ) {
          results.invalidTokens.push(token);
        }
        results.failure++;
      }
    } catch (error) {
      console.error(`FCM Error for token ${token.substring(0, 20)}:`, error);
      results.failure++;
    }
  });

  await Promise.all(promises);

  console.log(
    `[FCM] Sent: ${results.success}/${tokens.length}, Invalid: ${results.invalidTokens.length}`
  );

  return results;
}

/**
 * 獲取用戶的 FCM Tokens（從 user_devices 表）
 */
export async function getUserTokens(
  supabase: ReturnType<typeof createClient>,
  userId: string
): Promise<string[]> {
  const { data, error } = await supabase
    .from("user_devices")
    .select("fcm_token")
    .eq("user_id", userId);

  if (error) {
    console.error("Failed to get user tokens:", error);
    return [];
  }

  return data?.map((d) => d.fcm_token) || [];
}

/**
 * 清理無效的 Tokens
 */
export async function cleanupInvalidTokens(
  supabase: ReturnType<typeof createClient>,
  tokens: string[]
): Promise<number> {
  if (tokens.length === 0) return 0;

  const { data, error } = await supabase.rpc("remove_invalid_tokens", {
    p_tokens: tokens,
  });

  if (error) {
    console.error("Failed to cleanup invalid tokens:", error);
    return 0;
  }

  console.log(`[FCM] Cleaned up ${data} invalid tokens`);
  return data || 0;
}


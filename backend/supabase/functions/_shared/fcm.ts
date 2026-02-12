/**
 * Firebase Cloud Messaging helper for sending push notifications
 * via the FCM HTTP v1 API.
 */

interface FCMNotification {
  title: string;
  body: string;
}

interface FCMMessage {
  token: string;
  notification: FCMNotification;
  data?: Record<string, string>;
}

/**
 * Gets a Google OAuth2 access token using the service account credentials.
 * The FIREBASE_SERVICE_ACCOUNT_KEY env var should be a base64-encoded
 * JSON service account key file.
 */
async function getGoogleAccessToken(): Promise<string> {
  const keyBase64 = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_KEY");
  if (!keyBase64) {
    throw new Error("FIREBASE_SERVICE_ACCOUNT_KEY is not set");
  }

  const keyJson = JSON.parse(atob(keyBase64));
  const now = Math.floor(Date.now() / 1000);

  // Create JWT header and claims
  const header = { alg: "RS256", typ: "JWT" };
  const claims = {
    iss: keyJson.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  };

  // Base64url encode
  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj))
      .replace(/\+/g, "-")
      .replace(/\//g, "_")
      .replace(/=+$/, "");

  const unsignedToken = `${enc(header)}.${enc(claims)}`;

  // Import the private key and sign
  const pemContents = keyJson.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");

  const binaryKey = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    binaryKey,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    cryptoKey,
    new TextEncoder().encode(unsignedToken)
  );

  const sig = btoa(String.fromCharCode(...new Uint8Array(signature)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

  const jwt = `${unsignedToken}.${sig}`;

  // Exchange JWT for access token
  const tokenResponse = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenResponse.json();
  if (!tokenData.access_token) {
    throw new Error(`Failed to get Google access token: ${JSON.stringify(tokenData)}`);
  }

  return tokenData.access_token;
}

/**
 * Sends a push notification to a single device token via FCM HTTP v1 API.
 */
async function sendSingleNotification(
  accessToken: string,
  projectId: string,
  message: FCMMessage
): Promise<{ success: boolean; token: string; error?: string }> {
  try {
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            token: message.token,
            notification: message.notification,
            data: message.data || {},
          },
        }),
      }
    );

    if (!response.ok) {
      const errorBody = await response.text();
      // Check if token is invalid/unregistered
      if (
        errorBody.includes("NOT_FOUND") ||
        errorBody.includes("UNREGISTERED")
      ) {
        return { success: false, token: message.token, error: "unregistered" };
      }
      return { success: false, token: message.token, error: errorBody };
    }

    return { success: true, token: message.token };
  } catch (err) {
    return {
      success: false,
      token: message.token,
      error: (err as Error).message,
    };
  }
}

/**
 * Sends push notifications to multiple device tokens.
 * Returns results including which tokens failed (for cleanup).
 */
export async function sendBatchNotification(
  tokens: string[],
  notification: FCMNotification,
  data?: Record<string, string>
): Promise<{
  sent: number;
  failed: number;
  unregistered_tokens: string[];
}> {
  if (tokens.length === 0) {
    return { sent: 0, failed: 0, unregistered_tokens: [] };
  }

  const projectId = Deno.env.get("FIREBASE_PROJECT_ID");
  if (!projectId) {
    throw new Error("FIREBASE_PROJECT_ID is not set");
  }

  const accessToken = await getGoogleAccessToken();

  const results = await Promise.allSettled(
    tokens.map((token) =>
      sendSingleNotification(accessToken, projectId, {
        token,
        notification,
        data,
      })
    )
  );

  let sent = 0;
  let failed = 0;
  const unregistered_tokens: string[] = [];

  for (const result of results) {
    if (result.status === "fulfilled" && result.value.success) {
      sent++;
    } else {
      failed++;
      if (
        result.status === "fulfilled" &&
        result.value.error === "unregistered"
      ) {
        unregistered_tokens.push(result.value.token);
      }
    }
  }

  return { sent, failed, unregistered_tokens };
}

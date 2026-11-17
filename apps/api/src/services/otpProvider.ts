import { createHash, randomInt } from "crypto";
import { env } from "../config/env";
import { ErrorCodes, httpError } from "../utils/errors";

export type OtpSendResult = {
  provider: "mock" | "msg91" | "2factor";
  /** Present only in mock mode for local testing */
  debugCode?: string;
};

const MSG91_SEND_OTP_URL = "https://control.msg91.com/api/v5/otp";

function hashCode(code: string): string {
  return createHash("sha256").update(`${env.SESSION_SECRET}:${code}`).digest("hex");
}

export function generateOtpCode(): string {
  if (env.OTP_PROVIDER === "mock" && env.OTP_MOCK_CODE) {
    return env.OTP_MOCK_CODE;
  }
  const max = 10 ** env.OTP_LENGTH;
  const n = randomInt(0, max);
  return String(n).padStart(env.OTP_LENGTH, "0");
}

export function hashOtp(code: string): string {
  return hashCode(code);
}

export function verifyOtpHash(code: string, codeHash: string): boolean {
  return hashCode(code) === codeHash;
}

/** MSG91 expects digits with country code, no leading +. */
function msg91Mobile(phoneE164: string): string {
  return phoneE164.replace(/\D/g, "");
}

function requireMsg91Config(): {
  authKey: string;
  templateId: string;
  senderId: string;
} {
  const authKey = env.MSG91_AUTH_KEY?.trim();
  const templateId = env.MSG91_TEMPLATE_ID?.trim();
  const senderId = env.MSG91_SENDER_ID?.trim();
  const missing: string[] = [];
  if (!authKey) missing.push("MSG91_AUTH_KEY");
  if (!templateId) missing.push("MSG91_TEMPLATE_ID");
  if (!senderId) missing.push("MSG91_SENDER_ID");
  if (missing.length > 0) {
    throw httpError(
      503,
      `MSG91 is not configured. Set ${missing.join(", ")} (or set OTP_PROVIDER=mock for local/dev).`,
      ErrorCodes.OTP_PROVIDER_MISCONFIGURED
    );
  }
  return { authKey: authKey!, templateId: templateId!, senderId: senderId! };
}

/**
 * Send OTP via MSG91 Send OTP API (v5).
 * We pass our own `otp` so verify stays against the in-memory challenge hash.
 * Template must be India DLT-approved; sender id is set on the MSG91/DLT template.
 * @see https://docs.msg91.com/otp
 */
async function sendViaMsg91(phone: string, code: string): Promise<OtpSendResult> {
  const { authKey, templateId, senderId } = requireMsg91Config();
  const mobile = msg91Mobile(phone);
  const otpExpiryMinutes = Math.max(1, Math.ceil(env.OTP_EXPIRY_SECONDS / 60));

  const url = new URL(MSG91_SEND_OTP_URL);
  url.searchParams.set("template_id", templateId);
  url.searchParams.set("mobile", mobile);
  url.searchParams.set("otp", code);
  url.searchParams.set("otp_length", String(env.OTP_LENGTH));
  url.searchParams.set("otp_expiry", String(otpExpiryMinutes));
  // Documented for ops; MSG91 OTP templates also bind sender in the dashboard.
  url.searchParams.set("sender", senderId);

  let response: Response;
  try {
    response = await fetch(url, {
      method: "POST",
      headers: {
        authkey: authKey,
        "Content-Type": "application/json",
        Accept: "application/json",
      },
      // Body reserved for template variables if the DLT template defines named params.
      body: JSON.stringify({}),
    });
  } catch (err) {
    console.error(
      JSON.stringify({
        level: "error",
        msg: "msg91_otp_network_error",
        phone,
        error: err instanceof Error ? err.message : String(err),
      })
    );
    throw httpError(
      502,
      "Failed to reach MSG91. Try again shortly.",
      ErrorCodes.OTP_SEND_FAILED
    );
  }

  let payload: { type?: string; message?: string; request_id?: string } = {};
  try {
    payload = (await response.json()) as typeof payload;
  } catch {
    // non-JSON body
  }

  // MSG91 may return HTTP 200 with { type: "error" }.
  if (!response.ok || payload.type === "error") {
    console.error(
      JSON.stringify({
        level: "error",
        msg: "msg91_otp_send_failed",
        phone,
        httpStatus: response.status,
        providerMessage: payload.message ?? null,
      })
    );
    throw httpError(
      502,
      "MSG91 could not send OTP. Check template/DLT status and try again.",
      ErrorCodes.OTP_SEND_FAILED
    );
  }

  console.log(
    JSON.stringify({
      level: "info",
      msg: "msg91_otp_sent",
      phone,
      templateId,
      senderId,
      requestId: payload.request_id ?? null,
    })
  );

  return { provider: "msg91" };
}

/**
 * Send OTP via configured provider.
 * mock — logs code; never call real SMS.
 * msg91 — real India SMS via MSG91; verify remains against stored challenge.
 * 2factor — stub until wired (same challenge design).
 */
export async function sendOtp(phone: string, code: string): Promise<OtpSendResult> {
  switch (env.OTP_PROVIDER) {
    case "mock": {
      console.log(`[OTP mock] phone=${phone} code=${code}`);
      return { provider: "mock", debugCode: code };
    }
    case "msg91":
      return sendViaMsg91(phone, code);
    case "2factor": {
      if (!env.TWO_FACTOR_API_KEY?.trim()) {
        throw httpError(
          503,
          "2Factor is not configured. Set TWO_FACTOR_API_KEY (or set OTP_PROVIDER=mock for local/dev).",
          ErrorCodes.OTP_PROVIDER_MISCONFIGURED
        );
      }
      // Stub: replace with 2Factor.in API call when chosen over MSG91.
      console.warn(`[OTP 2factor] stub send to ${phone}`);
      return { provider: "2factor" };
    }
    default:
      throw httpError(500, "Unknown OTP_PROVIDER", ErrorCodes.INTERNAL);
  }
}

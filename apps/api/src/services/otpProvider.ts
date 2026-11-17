import { createHash, randomInt } from "crypto";
import { env } from "../config/env";

export type OtpSendResult = {
  provider: "mock" | "msg91" | "2factor";
  /** Present only in mock mode for local testing */
  debugCode?: string;
};

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

/**
 * Send OTP via configured provider.
 * mock — logs code; never call real SMS.
 * msg91 / 2factor — stubs that require env keys (wire SDKs in Phase 1 exit).
 */
export async function sendOtp(phone: string, code: string): Promise<OtpSendResult> {
  switch (env.OTP_PROVIDER) {
    case "mock": {
      console.log(`[OTP mock] phone=${phone} code=${code}`);
      return { provider: "mock", debugCode: code };
    }
    case "msg91": {
      if (!env.MSG91_AUTH_KEY || !env.MSG91_TEMPLATE_ID) {
        throw new Error("MSG91_AUTH_KEY and MSG91_TEMPLATE_ID required when OTP_PROVIDER=msg91");
      }
      // Stub: replace with MSG91 Flow/OTP API once DLT template is approved.
      console.warn(`[OTP msg91] stub send to ${phone} (template ${env.MSG91_TEMPLATE_ID})`);
      return { provider: "msg91" };
    }
    case "2factor": {
      if (!env.TWO_FACTOR_API_KEY) {
        throw new Error("TWO_FACTOR_API_KEY required when OTP_PROVIDER=2factor");
      }
      // Stub: replace with 2Factor.in API call.
      console.warn(`[OTP 2factor] stub send to ${phone}`);
      return { provider: "2factor" };
    }
    default:
      throw new Error(`Unknown OTP_PROVIDER`);
  }
}

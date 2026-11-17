#!/usr/bin/env bash
# Smoke OTP providers: mock send/verify-hash still works; msg91 without keys → clear error.
# Does not call real MSG91. Never requires real secrets.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== typecheck =="
npm run typecheck

echo "== mock provider: send + hash verify =="
OTP_PROVIDER=mock OTP_MOCK_CODE=123456 SESSION_SECRET=smoke-secret \
  npx tsx --eval '
import { generateOtpCode, hashOtp, sendOtp, verifyOtpHash } from "./src/services/otpProvider.ts";

async function main() {
  const code = generateOtpCode();
  if (code !== "123456") throw new Error(`expected mock code 123456, got ${code}`);
  const sent = await sendOtp("+919876543210", code);
  if (sent.provider !== "mock" || sent.debugCode !== code) {
    throw new Error(`bad mock send result: ${JSON.stringify(sent)}`);
  }
  if (!verifyOtpHash(code, hashOtp(code))) throw new Error("hash verify failed");
  console.log("mock OTP OK");
}
main().catch((e) => {
  console.error(e);
  process.exit(1);
});
'

echo "== msg91 without keys: OTP_PROVIDER_MISCONFIGURED =="
OTP_PROVIDER=msg91 MSG91_AUTH_KEY= MSG91_TEMPLATE_ID= MSG91_SENDER_ID= SESSION_SECRET=smoke-secret \
  npx tsx --eval '
import { sendOtp } from "./src/services/otpProvider.ts";
import { HttpError } from "./src/utils/errors.ts";

async function main() {
  let err;
  try {
    await sendOtp("+919876543210", "654321");
  } catch (e) {
    err = e;
  }
  if (!(err instanceof HttpError)) throw new Error(`expected HttpError, got ${err}`);
  if (err.status !== 503) throw new Error(`expected status 503, got ${err.status}`);
  if (err.code !== "OTP_PROVIDER_MISCONFIGURED") {
    throw new Error(`expected OTP_PROVIDER_MISCONFIGURED, got ${err.code}`);
  }
  if (!String(err.message).includes("MSG91")) {
    throw new Error(`expected MSG91 in message, got ${err.message}`);
  }
  console.log("msg91 misconfig OK:", err.message);
}
main().catch((e) => {
  console.error(e);
  process.exit(1);
});
'

echo "All OTP smoke checks passed."

export class HttpError extends Error {
  status: number;
  code?: string;

  constructor(status: number, message: string, code?: string) {
    super(message);
    this.name = "HttpError";
    this.status = status;
    this.code = code;
  }
}

export function httpError(status: number, message: string, code?: string): HttpError {
  return new HttpError(status, message, code);
}

/** Error codes used by soft-launch clients */
export const ErrorCodes = {
  VALIDATION_ERROR: "VALIDATION_ERROR",
  RATE_LIMITED: "RATE_LIMITED",
  UNAUTHORIZED: "UNAUTHORIZED",
  FORBIDDEN: "FORBIDDEN",
  NOT_FOUND: "NOT_FOUND",
  OTP_INVALID_PHONE: "OTP_INVALID_PHONE",
  OTP_NONE_PENDING: "OTP_NONE_PENDING",
  OTP_EXPIRED: "OTP_EXPIRED",
  OTP_TOO_MANY_ATTEMPTS: "OTP_TOO_MANY_ATTEMPTS",
  OTP_INCORRECT: "OTP_INCORRECT",
  OTP_PROVIDER_MISCONFIGURED: "OTP_PROVIDER_MISCONFIGURED",
  OTP_SEND_FAILED: "OTP_SEND_FAILED",
  SEATS_FULL: "SEATS_FULL",
  TRIP_STARTED: "TRIP_STARTED",
  TRIP_NOT_OPEN: "TRIP_NOT_OPEN",
  SPAM_TRIP_LIMIT: "SPAM_TRIP_LIMIT",
  SPAM_DUPLICATE_TRIP: "SPAM_DUPLICATE_TRIP",
  DEPART_TOO_SOON: "DEPART_TOO_SOON",
  VERIFICATION_REQUIRED: "VERIFICATION_REQUIRED",
  VERIFICATION_PENDING: "VERIFICATION_PENDING",
  VERIFICATION_ALREADY: "VERIFICATION_ALREADY",
  RATING_NOT_ELIGIBLE: "RATING_NOT_ELIGIBLE",
  RATING_ALREADY: "RATING_ALREADY",
  USER_BLOCKED: "USER_BLOCKED",
  INTERNAL: "INTERNAL",
} as const;

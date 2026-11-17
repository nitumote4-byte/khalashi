import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().default("postgres://khalashi:khalashi@localhost:5432/khalashi"),

  // Auth / OTP
  // mock = log OTP to console (dev). msg91 | 2factor for production SMS after DLT approval.
  OTP_PROVIDER: z.enum(["mock", "msg91", "2factor"]).default("mock"),
  OTP_EXPIRY_SECONDS: z.coerce.number().default(300),
  OTP_LENGTH: z.coerce.number().default(6),
  OTP_MOCK_CODE: z.string().optional(),
  SESSION_SECRET: z.string().default("change-me-in-production"),
  SESSION_TTL_SECONDS: z.coerce.number().default(604800),

  // MSG91 (when OTP_PROVIDER=msg91) — requires India DLT-registered template
  MSG91_AUTH_KEY: z.string().optional(),
  MSG91_TEMPLATE_ID: z.string().optional(),
  MSG91_SENDER_ID: z.string().optional(),

  // 2Factor (when OTP_PROVIDER=2factor) — requires India DLT-registered template
  TWO_FACTOR_API_KEY: z.string().optional(),

  // Soft-launch rate limits / spam guards
  RATE_LIMIT_OTP_PER_PHONE: z.coerce.number().default(3),
  RATE_LIMIT_OTP_WINDOW_SEC: z.coerce.number().default(60),
  RATE_LIMIT_OTP_PER_IP: z.coerce.number().default(20),
  RATE_LIMIT_SEARCH_PER_USER: z.coerce.number().default(30),
  RATE_LIMIT_BOOK_PER_USER: z.coerce.number().default(10),
  RATE_LIMIT_TRIP_POST_PER_USER: z.coerce.number().default(5),
  RATE_LIMIT_ACTION_WINDOW_SEC: z.coerce.number().default(60),
  MAX_TRIPS_PER_DRIVER_PER_DAY: z.coerce.number().default(8),
  MIN_DEPART_AHEAD_MINUTES: z.coerce.number().default(30),
});

export type Env = z.infer<typeof envSchema>;

export const env: Env = envSchema.parse(process.env);

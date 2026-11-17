import dotenv from "dotenv";
import { z } from "zod";

dotenv.config();

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().default("postgres://khalashi:khalashi@localhost:5432/khalashi"),
  OTP_PROVIDER: z.enum(["mock", "msg91", "2factor"]).default("mock"),
  OTP_EXPIRY_SECONDS: z.coerce.number().default(300),
  OTP_LENGTH: z.coerce.number().default(6),
  OTP_MOCK_CODE: z.string().optional(),
  SESSION_SECRET: z.string().default("change-me-in-production"),
  SESSION_TTL_SECONDS: z.coerce.number().default(604800),
  MSG91_AUTH_KEY: z.string().optional(),
  MSG91_TEMPLATE_ID: z.string().optional(),
  MSG91_SENDER_ID: z.string().optional(),
  TWO_FACTOR_API_KEY: z.string().optional(),
});

export type Env = z.infer<typeof envSchema>;

export const env: Env = envSchema.parse(process.env);

CREATE TYPE "public"."session_purpose" AS ENUM('session', 'pat');--> statement-breakpoint
ALTER TABLE "sessions" ADD COLUMN "label" varchar(64);--> statement-breakpoint
ALTER TABLE "sessions" ADD COLUMN "purpose" "session_purpose" DEFAULT 'session' NOT NULL;--> statement-breakpoint
ALTER TABLE "sessions" ADD COLUMN "token_prefix" varchar(12);--> statement-breakpoint
CREATE INDEX "sessions_user_purpose_idx" ON "sessions" USING btree ("user_id","purpose");
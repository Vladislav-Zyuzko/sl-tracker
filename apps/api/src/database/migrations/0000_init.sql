CREATE TYPE "public"."access_entry_source" AS ENUM('config', 'manual', 'invitation');--> statement-breakpoint
CREATE TYPE "public"."issue_history_kind" AS ENUM('issue_created', 'title_changed', 'description_changed', 'status_changed', 'priority_changed', 'story_points_changed', 'author_changed', 'assignee_changed', 'attachment_added', 'attachment_removed', 'link_added', 'link_removed', 'comment_deleted');--> statement-breakpoint
CREATE TYPE "public"."notification_channel" AS ENUM('in_app');--> statement-breakpoint
CREATE TYPE "public"."notification_type" AS ENUM('issue_assigned', 'issue_author_assigned', 'issue_status_changed', 'issue_commented', 'issue_mentioned', 'project_member_joined');--> statement-breakpoint
CREATE TYPE "public"."project_role" AS ENUM('admin', 'member', 'reader');--> statement-breakpoint
CREATE TYPE "public"."session_kind" AS ENUM('cookie', 'bearer');--> statement-breakpoint
CREATE TYPE "public"."status_category" AS ENUM('open', 'in_progress', 'done');--> statement-breakpoint
CREATE TABLE "users" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"display_name" varchar(255) NOT NULL,
	"email" varchar(320) NOT NULL,
	"avatar_url" text,
	"last_login_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "identities" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"provider" varchar(32) NOT NULL,
	"external_id" varchar(255) NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "access_entries" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"email" varchar(320) NOT NULL,
	"source" "access_entry_source" NOT NULL,
	"is_instance_owner" boolean DEFAULT false NOT NULL,
	"added_by_user_id" uuid,
	"user_id" uuid,
	"first_login_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "sessions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"kind" "session_kind" NOT NULL,
	"token_hash" char(64) NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	"revoked_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "project_slugs" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid,
	"slug" varchar(40) NOT NULL,
	"is_current" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"retired_at" timestamp with time zone,
	CONSTRAINT "project_slugs_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "projects" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" varchar(5000),
	"slug" varchar(40) NOT NULL,
	"cover_object_key" varchar(512),
	"cover_content_type" varchar(100),
	"cover_size_bytes" integer,
	"created_by_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "projects_cover_size_check" CHECK ("projects"."cover_size_bytes" is null or ("projects"."cover_size_bytes" > 0 and "projects"."cover_size_bytes" <= 5242880))
);
--> statement-breakpoint
CREATE TABLE "project_members" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"role" "project_role" NOT NULL,
	"invitation_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "invitations" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"token" varchar(64) NOT NULL,
	"role" "project_role" NOT NULL,
	"expires_at" timestamp with time zone NOT NULL,
	"revoked_at" timestamp with time zone,
	"revoked_by_user_id" uuid,
	"created_by_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "invitations_role_check" CHECK ("invitations"."role" in ('member', 'reader'))
);
--> statement-breakpoint
CREATE TABLE "queue_keys" (
	"key" varchar(10) PRIMARY KEY NOT NULL,
	"queue_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "queue_keys_format_check" CHECK ("queue_keys"."key" ~ '^[A-Z][A-Z0-9]{1,9}$')
);
--> statement-breakpoint
CREATE TABLE "queues" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"project_id" uuid NOT NULL,
	"key" varchar(10) NOT NULL,
	"name" varchar(100) NOT NULL,
	"description" varchar(1000),
	"last_issue_number" integer DEFAULT 0 NOT NULL,
	"created_by_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "queues_key_format_check" CHECK ("queues"."key" ~ '^[A-Z][A-Z0-9]{1,9}$'),
	CONSTRAINT "queues_last_issue_number_check" CHECK ("queues"."last_issue_number" >= 0)
);
--> statement-breakpoint
CREATE TABLE "statuses" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"queue_id" uuid NOT NULL,
	"key" varchar(32) NOT NULL,
	"name" varchar(50) NOT NULL,
	"category" "status_category" NOT NULL,
	"position" smallint NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "issues" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"queue_id" uuid NOT NULL,
	"number" integer NOT NULL,
	"key" varchar(21) NOT NULL,
	"title" varchar(255) NOT NULL,
	"description" varchar(100000),
	"status_id" uuid NOT NULL,
	"priority" smallint DEFAULT 50 NOT NULL,
	"story_points" smallint,
	"author_id" uuid NOT NULL,
	"created_by_user_id" uuid NOT NULL,
	"assignee_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "issues_number_check" CHECK ("issues"."number" > 0),
	CONSTRAINT "issues_priority_check" CHECK ("issues"."priority" between 0 and 100 and "issues"."priority" % 10 = 0),
	CONSTRAINT "issues_story_points_check" CHECK ("issues"."story_points" is null or "issues"."story_points" in (1, 2, 3, 5, 8, 13))
);
--> statement-breakpoint
CREATE TABLE "comments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"issue_id" uuid NOT NULL,
	"author_id" uuid NOT NULL,
	"body" varchar(10000) NOT NULL,
	"edited_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "mentions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"issue_id" uuid NOT NULL,
	"comment_id" uuid,
	"mentioned_user_id" uuid NOT NULL,
	"created_by_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "attachments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"issue_id" uuid NOT NULL,
	"object_key" varchar(512) NOT NULL,
	"file_name" varchar(255) NOT NULL,
	"content_type" varchar(255) NOT NULL,
	"size_bytes" bigint NOT NULL,
	"uploaded_by_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "attachments_size_check" CHECK ("attachments"."size_bytes" > 0 and "attachments"."size_bytes" <= 26214400)
);
--> statement-breakpoint
CREATE TABLE "issue_links" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"issue_id" uuid NOT NULL,
	"url" varchar(2048) NOT NULL,
	"title" varchar(100),
	"created_by_user_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "issue_links_scheme_check" CHECK ("issue_links"."url" ~ '^https?://')
);
--> statement-breakpoint
CREATE TABLE "issue_history" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"issue_id" uuid NOT NULL,
	"actor_id" uuid,
	"kind" "issue_history_kind" NOT NULL,
	"group_id" uuid NOT NULL,
	"old_value" varchar(512),
	"new_value" varchar(512),
	"old_ref_id" uuid,
	"new_ref_id" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "notification_settings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"type" "notification_type" NOT NULL,
	"channel" "notification_channel" DEFAULT 'in_app' NOT NULL,
	"enabled" boolean DEFAULT true NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "notifications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"recipient_id" uuid NOT NULL,
	"type" "notification_type" NOT NULL,
	"channel" "notification_channel" DEFAULT 'in_app' NOT NULL,
	"actor_id" uuid,
	"project_id" uuid,
	"issue_id" uuid,
	"comment_id" uuid,
	"payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
	"read_at" timestamp with time zone,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "identities" ADD CONSTRAINT "identities_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "access_entries" ADD CONSTRAINT "access_entries_added_by_user_id_users_id_fk" FOREIGN KEY ("added_by_user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "access_entries" ADD CONSTRAINT "access_entries_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "project_slugs" ADD CONSTRAINT "project_slugs_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_slug_project_slugs_slug_fk" FOREIGN KEY ("slug") REFERENCES "public"."project_slugs"("slug") ON DELETE restrict ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "projects" ADD CONSTRAINT "projects_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "project_members" ADD CONSTRAINT "project_members_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "project_members" ADD CONSTRAINT "project_members_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "project_members" ADD CONSTRAINT "project_members_invitation_id_invitations_id_fk" FOREIGN KEY ("invitation_id") REFERENCES "public"."invitations"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_revoked_by_user_id_users_id_fk" FOREIGN KEY ("revoked_by_user_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "invitations" ADD CONSTRAINT "invitations_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "queue_keys" ADD CONSTRAINT "queue_keys_queue_id_queues_id_fk" FOREIGN KEY ("queue_id") REFERENCES "public"."queues"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "queues" ADD CONSTRAINT "queues_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "queues" ADD CONSTRAINT "queues_key_queue_keys_key_fk" FOREIGN KEY ("key") REFERENCES "public"."queue_keys"("key") ON DELETE restrict ON UPDATE cascade;--> statement-breakpoint
ALTER TABLE "queues" ADD CONSTRAINT "queues_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "statuses" ADD CONSTRAINT "statuses_queue_id_queues_id_fk" FOREIGN KEY ("queue_id") REFERENCES "public"."queues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issues" ADD CONSTRAINT "issues_queue_id_queues_id_fk" FOREIGN KEY ("queue_id") REFERENCES "public"."queues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issues" ADD CONSTRAINT "issues_status_id_statuses_id_fk" FOREIGN KEY ("status_id") REFERENCES "public"."statuses"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issues" ADD CONSTRAINT "issues_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issues" ADD CONSTRAINT "issues_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issues" ADD CONSTRAINT "issues_assignee_id_users_id_fk" FOREIGN KEY ("assignee_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "comments" ADD CONSTRAINT "comments_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "comments" ADD CONSTRAINT "comments_author_id_users_id_fk" FOREIGN KEY ("author_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mentions" ADD CONSTRAINT "mentions_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mentions" ADD CONSTRAINT "mentions_comment_id_comments_id_fk" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mentions" ADD CONSTRAINT "mentions_mentioned_user_id_users_id_fk" FOREIGN KEY ("mentioned_user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "mentions" ADD CONSTRAINT "mentions_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "attachments" ADD CONSTRAINT "attachments_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "attachments" ADD CONSTRAINT "attachments_uploaded_by_user_id_users_id_fk" FOREIGN KEY ("uploaded_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issue_links" ADD CONSTRAINT "issue_links_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issue_links" ADD CONSTRAINT "issue_links_created_by_user_id_users_id_fk" FOREIGN KEY ("created_by_user_id") REFERENCES "public"."users"("id") ON DELETE restrict ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issue_history" ADD CONSTRAINT "issue_history_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "issue_history" ADD CONSTRAINT "issue_history_actor_id_users_id_fk" FOREIGN KEY ("actor_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notification_settings" ADD CONSTRAINT "notification_settings_user_id_users_id_fk" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_recipient_id_users_id_fk" FOREIGN KEY ("recipient_id") REFERENCES "public"."users"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_actor_id_users_id_fk" FOREIGN KEY ("actor_id") REFERENCES "public"."users"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_project_id_projects_id_fk" FOREIGN KEY ("project_id") REFERENCES "public"."projects"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_issue_id_issues_id_fk" FOREIGN KEY ("issue_id") REFERENCES "public"."issues"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_comment_id_comments_id_fk" FOREIGN KEY ("comment_id") REFERENCES "public"."comments"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "users_email_lower_idx" ON "users" USING btree (lower("email"));--> statement-breakpoint
CREATE UNIQUE INDEX "identities_provider_external_id_key" ON "identities" USING btree ("provider","external_id");--> statement-breakpoint
CREATE INDEX "identities_user_id_idx" ON "identities" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "access_entries_email_lower_key" ON "access_entries" USING btree (lower("email"));--> statement-breakpoint
CREATE INDEX "access_entries_created_at_idx" ON "access_entries" USING btree ("created_at" DESC NULLS FIRST);--> statement-breakpoint
CREATE INDEX "access_entries_owner_idx" ON "access_entries" USING btree ("id") WHERE "access_entries"."is_instance_owner";--> statement-breakpoint
CREATE INDEX "access_entries_user_id_idx" ON "access_entries" USING btree ("user_id");--> statement-breakpoint
CREATE UNIQUE INDEX "sessions_token_hash_key" ON "sessions" USING btree ("token_hash");--> statement-breakpoint
CREATE INDEX "sessions_user_id_idx" ON "sessions" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "sessions_active_expires_at_idx" ON "sessions" USING btree ("expires_at") WHERE "sessions"."revoked_at" is null;--> statement-breakpoint
CREATE UNIQUE INDEX "project_slugs_slug_key" ON "project_slugs" USING btree ("slug");--> statement-breakpoint
CREATE UNIQUE INDEX "project_slugs_current_key" ON "project_slugs" USING btree ("project_id") WHERE "project_slugs"."is_current";--> statement-breakpoint
CREATE INDEX "project_slugs_project_id_idx" ON "project_slugs" USING btree ("project_id");--> statement-breakpoint
CREATE UNIQUE INDEX "projects_slug_key" ON "projects" USING btree ("slug");--> statement-breakpoint
CREATE UNIQUE INDEX "project_members_project_user_key" ON "project_members" USING btree ("project_id","user_id");--> statement-breakpoint
CREATE INDEX "project_members_user_id_idx" ON "project_members" USING btree ("user_id");--> statement-breakpoint
CREATE INDEX "project_members_admins_idx" ON "project_members" USING btree ("project_id") WHERE "project_members"."role" = 'admin';--> statement-breakpoint
CREATE INDEX "project_members_invitation_id_idx" ON "project_members" USING btree ("invitation_id");--> statement-breakpoint
CREATE UNIQUE INDEX "invitations_token_key" ON "invitations" USING btree ("token");--> statement-breakpoint
CREATE INDEX "invitations_project_id_created_at_idx" ON "invitations" USING btree ("project_id","created_at" DESC NULLS FIRST);--> statement-breakpoint
CREATE UNIQUE INDEX "queue_keys_queue_id_key" ON "queue_keys" USING btree ("queue_id");--> statement-breakpoint
CREATE UNIQUE INDEX "queues_key_key" ON "queues" USING btree ("key");--> statement-breakpoint
CREATE INDEX "queues_project_id_name_idx" ON "queues" USING btree ("project_id","name");--> statement-breakpoint
CREATE UNIQUE INDEX "statuses_queue_id_key_key" ON "statuses" USING btree ("queue_id","key");--> statement-breakpoint
CREATE UNIQUE INDEX "statuses_queue_id_position_key" ON "statuses" USING btree ("queue_id","position");--> statement-breakpoint
CREATE INDEX "statuses_queue_id_position_idx" ON "statuses" USING btree ("queue_id","position");--> statement-breakpoint
CREATE INDEX "statuses_category_idx" ON "statuses" USING btree ("category");--> statement-breakpoint
CREATE UNIQUE INDEX "issues_key_key" ON "issues" USING btree ("key");--> statement-breakpoint
CREATE UNIQUE INDEX "issues_queue_id_number_key" ON "issues" USING btree ("queue_id","number");--> statement-breakpoint
CREATE INDEX "issues_queue_id_status_id_idx" ON "issues" USING btree ("queue_id","status_id");--> statement-breakpoint
CREATE INDEX "issues_queue_id_priority_number_idx" ON "issues" USING btree ("queue_id","priority" DESC NULLS FIRST,"number" DESC NULLS FIRST);--> statement-breakpoint
CREATE INDEX "issues_assignee_status_idx" ON "issues" USING btree ("assignee_id","status_id") WHERE "issues"."assignee_id" is not null;--> statement-breakpoint
CREATE INDEX "issues_title_fts_idx" ON "issues" USING gin (to_tsvector('russian', "title"));--> statement-breakpoint
CREATE INDEX "comments_issue_id_created_at_idx" ON "comments" USING btree ("issue_id","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "mentions_comment_user_key" ON "mentions" USING btree ("comment_id","mentioned_user_id") WHERE "mentions"."comment_id" is not null;--> statement-breakpoint
CREATE UNIQUE INDEX "mentions_issue_description_user_key" ON "mentions" USING btree ("issue_id","mentioned_user_id") WHERE "mentions"."comment_id" is null;--> statement-breakpoint
CREATE INDEX "mentions_mentioned_user_id_idx" ON "mentions" USING btree ("mentioned_user_id");--> statement-breakpoint
CREATE INDEX "mentions_issue_id_idx" ON "mentions" USING btree ("issue_id");--> statement-breakpoint
CREATE UNIQUE INDEX "attachments_object_key_key" ON "attachments" USING btree ("object_key");--> statement-breakpoint
CREATE INDEX "attachments_issue_id_created_at_idx" ON "attachments" USING btree ("issue_id","created_at");--> statement-breakpoint
CREATE INDEX "issue_links_issue_id_created_at_idx" ON "issue_links" USING btree ("issue_id","created_at");--> statement-breakpoint
CREATE INDEX "issue_history_issue_id_created_at_idx" ON "issue_history" USING btree ("issue_id","created_at" DESC NULLS FIRST,"id" DESC NULLS FIRST);--> statement-breakpoint
CREATE UNIQUE INDEX "notification_settings_user_type_channel_key" ON "notification_settings" USING btree ("user_id","type","channel");--> statement-breakpoint
CREATE INDEX "notifications_recipient_created_at_idx" ON "notifications" USING btree ("recipient_id","created_at" DESC NULLS FIRST);--> statement-breakpoint
CREATE INDEX "notifications_unread_idx" ON "notifications" USING btree ("recipient_id") WHERE "notifications"."read_at" is null;--> statement-breakpoint
CREATE INDEX "notifications_issue_id_idx" ON "notifications" USING btree ("issue_id");
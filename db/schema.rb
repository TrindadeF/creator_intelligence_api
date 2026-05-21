# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_21_143304) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "insights", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "video_id"
    t.string "insight_type", null: false
    t.string "title", null: false
    t.text "description"
    t.text "ai_summary"
    t.string "severity", default: "info"
    t.boolean "read", default: false
    t.boolean "dismissed", default: false
    t.string "generated_by", default: "system"
    t.jsonb "metadata", default: {}
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["insight_type"], name: "index_insights_on_insight_type"
    t.index ["read"], name: "index_insights_on_read"
    t.index ["severity"], name: "index_insights_on_severity"
    t.index ["user_id", "created_at"], name: "index_insights_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_insights_on_user_id"
    t.index ["video_id"], name: "index_insights_on_video_id"
  end

  create_table "social_accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "provider_account_id", null: false
    t.string "username"
    t.text "access_token"
    t.text "refresh_token"
    t.datetime "token_expires_at"
    t.datetime "connected_at"
    t.boolean "active", default: true
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_social_accounts_on_active"
    t.index ["provider", "provider_account_id"], name: "index_social_accounts_on_provider_and_provider_account_id", unique: true
    t.index ["user_id", "provider"], name: "index_social_accounts_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_social_accounts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "avatar_url"
    t.string "niche"
    t.text "bio"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.string "refresh_token"
    t.datetime "refresh_token_expires_at"
    t.boolean "active", default: true, null: false
    t.jsonb "settings", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["refresh_token"], name: "index_users_on_refresh_token"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token"
  end

  create_table "video_analytics", force: :cascade do |t|
    t.bigint "video_id", null: false
    t.bigint "views", default: 0
    t.bigint "likes", default: 0
    t.bigint "comments", default: 0
    t.bigint "shares", default: 0
    t.bigint "saves", default: 0
    t.bigint "watch_time", default: 0
    t.decimal "avg_watch_time", precision: 10, scale: 2, default: "0.0"
    t.decimal "retention_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "completion_rate", precision: 5, scale: 2, default: "0.0"
    t.decimal "engagement_rate", precision: 5, scale: 2, default: "0.0"
    t.integer "followers_gained", default: 0
    t.decimal "revenue", precision: 10, scale: 2, default: "0.0"
    t.datetime "collected_at", null: false
    t.string "collection_source", default: "api"
    t.jsonb "raw_data", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["collected_at"], name: "index_video_analytics_on_collected_at"
    t.index ["engagement_rate"], name: "index_video_analytics_on_engagement_rate"
    t.index ["video_id", "collected_at"], name: "index_video_analytics_on_video_id_and_collected_at"
    t.index ["video_id"], name: "index_video_analytics_on_video_id"
    t.index ["views"], name: "index_video_analytics_on_views"
  end

  create_table "videos", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "social_account_id", null: false
    t.string "external_video_id", null: false
    t.string "title"
    t.text "description"
    t.integer "duration_seconds"
    t.datetime "published_at"
    t.string "thumbnail_url"
    t.string "video_url"
    t.string "status", default: "published"
    t.jsonb "hashtags", default: []
    t.jsonb "metadata", default: {}
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_video_id"], name: "index_videos_on_external_video_id"
    t.index ["published_at"], name: "index_videos_on_published_at"
    t.index ["social_account_id", "external_video_id"], name: "index_videos_on_social_account_id_and_external_video_id", unique: true
    t.index ["social_account_id"], name: "index_videos_on_social_account_id"
    t.index ["status"], name: "index_videos_on_status"
    t.index ["user_id"], name: "index_videos_on_user_id"
  end

  add_foreign_key "insights", "users"
  add_foreign_key "insights", "videos"
  add_foreign_key "social_accounts", "users"
  add_foreign_key "video_analytics", "videos"
  add_foreign_key "videos", "social_accounts"
  add_foreign_key "videos", "users"
end

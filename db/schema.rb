# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_11_27_175524) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "citext"
  enable_extension "plpgsql"

  create_table "account_active_session_keys", primary_key: ["account_id", "session_id"], force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "session_id", null: false
    t.datetime "created_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "last_use", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_account_active_session_keys_on_account_id"
  end

  create_table "account_activity_times", force: :cascade do |t|
    t.datetime "last_activity_at", null: false
    t.datetime "last_login_at", null: false
    t.datetime "expired_at"
  end

  create_table "account_authentication_audit_logs", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.datetime "at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.text "message", null: false
    t.jsonb "metadata"
    t.index ["account_id", "at"], name: "audit_account_at_idx"
    t.index ["account_id"], name: "index_account_authentication_audit_logs_on_account_id"
    t.index ["at"], name: "audit_at_idx"
  end

  create_table "account_email_auth_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_identities", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.jsonb "info", default: {}, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_account_identities_on_account_id"
    t.index ["provider", "uid"], name: "index_account_identities_on_provider_and_uid", unique: true
  end

  create_table "account_jwt_refresh_keys", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.index ["account_id"], name: "account_jwt_rk_account_id_idx"
    t.index ["account_id"], name: "index_account_jwt_refresh_keys_on_account_id"
  end

  create_table "account_lockouts", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent"
  end

  create_table "account_login_change_keys", force: :cascade do |t|
    t.string "key", null: false
    t.string "login", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_login_failures", force: :cascade do |t|
    t.integer "number", default: 1, null: false
  end

  create_table "account_otp_keys", force: :cascade do |t|
    t.string "key", null: false
    t.integer "num_failures", default: 0, null: false
    t.datetime "last_use", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_password_change_times", force: :cascade do |t|
    t.datetime "changed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_password_hashes", force: :cascade do |t|
    t.string "password_hash", null: false
  end

  create_table "account_password_reset_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_previous_password_hashes", force: :cascade do |t|
    t.bigint "account_id"
    t.string "password_hash", null: false
    t.index ["account_id"], name: "index_account_previous_password_hashes_on_account_id"
  end

  create_table "account_recovery_codes", primary_key: ["id", "code"], force: :cascade do |t|
    t.integer "id", null: false
    t.string "code", null: false
  end

  create_table "account_remember_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "deadline", null: false
  end

  create_table "account_session_keys", force: :cascade do |t|
    t.string "key", null: false
  end

  create_table "account_sms_codes", force: :cascade do |t|
    t.string "phone_number", null: false
    t.integer "num_failures"
    t.string "code"
    t.datetime "code_issued_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_verification_keys", force: :cascade do |t|
    t.string "key", null: false
    t.datetime "requested_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
  end

  create_table "account_webauthn_keys", primary_key: ["account_id", "webauthn_id"], force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "webauthn_id", null: false
    t.string "public_key", null: false
    t.integer "sign_count", null: false
    t.datetime "last_use", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.index ["account_id"], name: "index_account_webauthn_keys_on_account_id"
  end

  create_table "account_webauthn_user_ids", force: :cascade do |t|
    t.string "webauthn_id", null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.citext "email", null: false
    t.string "status", default: "verified", null: false
    t.index ["email"], name: "index_accounts_on_email", unique: true, where: "((status)::text = ANY ((ARRAY['verified'::character varying, 'unverified'::character varying])::text[]))"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "account_id"
    t.string "title"
    t.text "body"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["account_id"], name: "index_posts_on_account_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "account_id"
    t.string "name", null: false
    t.index ["account_id"], name: "index_profiles_on_account_id"
  end

  add_foreign_key "account_activity_times", "accounts", column: "id"
  add_foreign_key "account_email_auth_keys", "accounts", column: "id"
  add_foreign_key "account_identities", "accounts", on_delete: :cascade
  add_foreign_key "account_lockouts", "accounts", column: "id"
  add_foreign_key "account_login_change_keys", "accounts", column: "id"
  add_foreign_key "account_login_failures", "accounts", column: "id"
  add_foreign_key "account_otp_keys", "accounts", column: "id"
  add_foreign_key "account_password_change_times", "accounts", column: "id"
  add_foreign_key "account_password_hashes", "accounts", column: "id"
  add_foreign_key "account_password_reset_keys", "accounts", column: "id"
  add_foreign_key "account_recovery_codes", "accounts", column: "id"
  add_foreign_key "account_remember_keys", "accounts", column: "id"
  add_foreign_key "account_session_keys", "accounts", column: "id"
  add_foreign_key "account_sms_codes", "accounts", column: "id"
  add_foreign_key "account_verification_keys", "accounts", column: "id"
  add_foreign_key "account_webauthn_user_ids", "accounts", column: "id"
  add_foreign_key "posts", "accounts"
  add_foreign_key "profiles", "accounts"
end

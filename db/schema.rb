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

ActiveRecord::Schema.define(version: 2020_04_09_145829) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "access_controls", force: :cascade do |t|
    t.string "access_level"
    t.string "agent_type"
    t.bigint "agent_id"
    t.string "resource_type"
    t.bigint "resource_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["agent_type", "agent_id"], name: "index_access_controls_on_agent_type_and_agent_id"
    t.index ["resource_type", "resource_id"], name: "index_access_controls_on_resource_type_and_resource_id"
  end

  create_table "actors", force: :cascade do |t|
    t.string "surname"
    t.string "given_name"
    t.string "email"
    t.string "psu_id"
    t.string "orcid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "default_alias"
    t.index ["psu_id"], name: "index_actors_on_psu_id"
  end

  create_table "api_tokens", force: :cascade do |t|
    t.string "token"
    t.string "app_name"
    t.string "admin_email"
    t.datetime "last_used_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["token"], name: "index_api_tokens_on_token", unique: true
  end

  create_table "bookmarks", id: :serial, force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_type"
    t.string "document_id"
    t.string "document_type"
    t.binary "title"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["document_id"], name: "index_bookmarks_on_document_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "file_resources", force: :cascade do |t|
    t.jsonb "file_data"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "file_version_memberships", force: :cascade do |t|
    t.bigint "work_version_id", null: false
    t.bigint "file_resource_id", null: false
    t.string "title"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["file_resource_id"], name: "index_file_version_memberships_on_file_resource_id"
    t.index ["work_version_id"], name: "index_file_version_memberships_on_work_version_id"
  end

  create_table "groups", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["name"], name: "index_groups_on_name"
  end

  create_table "legacy_identifiers", force: :cascade do |t|
    t.integer "version"
    t.string "old_id"
    t.string "resource_type", null: false
    t.bigint "resource_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["resource_type", "resource_id"], name: "index_legacy_identifiers_on_resource_type_and_resource_id"
    t.index ["version", "old_id"], name: "index_legacy_identifiers_on_version_and_old_id", unique: true
  end

  create_table "searches", id: :serial, force: :cascade do |t|
    t.binary "query_params"
    t.integer "user_id"
    t.string "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_searches_on_user_id"
  end

  create_table "user_group_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "group_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["group_id"], name: "index_user_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_user_group_memberships_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "access_id"
    t.string "email"
    t.string "provider"
    t.string "uid"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "actor_id", null: false
    t.index ["actor_id"], name: "index_users_on_actor_id"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type", null: false
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.jsonb "object"
    t.datetime "created_at"
    t.jsonb "object_changes"
    t.integer "work_version_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["work_version_id"], name: "index_versions_on_work_version_id"
  end

  create_table "work_version_creations", force: :cascade do |t|
    t.bigint "work_version_id", null: false
    t.string "alias"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "actor_id", null: false
    t.index ["actor_id"], name: "index_work_version_creations_on_actor_id"
    t.index ["work_version_id"], name: "index_work_version_creations_on_work_version_id"
  end

  create_table "work_versions", force: :cascade do |t|
    t.bigint "work_id"
    t.string "aasm_state"
    t.jsonb "metadata"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }
    t.integer "version_number", null: false
    t.string "doi"
    t.index ["work_id"], name: "index_work_versions_on_work_id"
  end

  create_table "works", force: :cascade do |t|
    t.string "work_type"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.uuid "uuid", default: -> { "uuid_generate_v4()" }
    t.string "doi"
    t.datetime "embargoed_until"
    t.bigint "depositor_id", null: false
    t.bigint "proxy_id"
    t.index ["depositor_id"], name: "index_works_on_depositor_id"
    t.index ["proxy_id"], name: "index_works_on_proxy_id"
  end

  add_foreign_key "file_version_memberships", "file_resources"
  add_foreign_key "file_version_memberships", "work_versions"
  add_foreign_key "user_group_memberships", "groups"
  add_foreign_key "user_group_memberships", "users"
  add_foreign_key "users", "actors"
  add_foreign_key "work_version_creations", "actors"
  add_foreign_key "work_version_creations", "work_versions"
  add_foreign_key "work_versions", "works"
  add_foreign_key "works", "actors", column: "depositor_id"
  add_foreign_key "works", "actors", column: "proxy_id"
end

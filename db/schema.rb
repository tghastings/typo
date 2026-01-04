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

ActiveRecord::Schema[8.0].define(version: 2026_01_04_120000) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles_categories", id: false, force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.index ["article_id"], name: "index_articles_categories_on_article_id"
    t.index ["category_id"], name: "index_articles_categories_on_category_id"
  end

  create_table "articles_tags", id: false, force: :cascade do |t|
    t.integer "article_id"
    t.integer "tag_id"
    t.index ["article_id"], name: "index_articles_tags_on_article_id"
    t.index ["tag_id"], name: "index_articles_tags_on_tag_id"
  end

  create_table "blogs", force: :cascade do |t|
    t.text "settings"
    t.string "base_url"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.integer "position"
    t.string "permalink"
    t.text "keywords"
    t.text "description"
    t.integer "parent_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categorizations", force: :cascade do |t|
    t.integer "article_id"
    t.integer "category_id"
    t.boolean "is_primary", default: false
    t.index ["article_id"], name: "index_categorizations_on_article_id"
    t.index ["category_id"], name: "index_categorizations_on_category_id"
  end

  create_table "contents", force: :cascade do |t|
    t.string "type"
    t.string "title"
    t.string "author"
    t.text "body"
    t.text "extended"
    t.text "excerpt"
    t.datetime "published_at"
    t.integer "user_id"
    t.string "permalink"
    t.string "guid"
    t.integer "text_filter_id"
    t.text "whiteboard"
    t.string "name"
    t.boolean "published", default: false
    t.boolean "allow_pings"
    t.boolean "allow_comments"
    t.string "post_type", default: "read"
    t.integer "blog_id", default: 1
    t.string "state"
    t.integer "parent_id"
    t.string "password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "redirect_url"
    t.boolean "indent_paragraphs", default: false
    t.index ["permalink"], name: "index_contents_on_permalink"
    t.index ["published_at"], name: "index_contents_on_published_at"
    t.index ["type"], name: "index_contents_on_type"
    t.index ["user_id"], name: "index_contents_on_user_id"
  end

  create_table "contents_tags", id: false, force: :cascade do |t|
    t.integer "article_id"
    t.integer "tag_id"
    t.index ["article_id"], name: "index_contents_tags_on_article_id"
    t.index ["tag_id"], name: "index_contents_tags_on_tag_id"
  end

  create_table "feedback", force: :cascade do |t|
    t.string "type"
    t.string "title"
    t.string "author"
    t.text "body"
    t.text "excerpt"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_id"
    t.string "guid"
    t.integer "text_filter_id"
    t.text "whiteboard"
    t.integer "article_id"
    t.string "email"
    t.string "url"
    t.string "ip", limit: 40
    t.string "blog_name"
    t.boolean "published", default: false
    t.datetime "published_at"
    t.string "state"
    t.boolean "status_confirmed"
    t.string "user_agent"
    t.index ["article_id"], name: "index_feedback_on_article_id"
    t.index ["user_id"], name: "index_feedback_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "content_id"
    t.integer "user_id"
    t.boolean "is_read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "pings", force: :cascade do |t|
    t.integer "article_id"
    t.string "url"
    t.datetime "created_at"
    t.index ["article_id"], name: "index_pings_on_article_id"
  end

  create_table "post_types", force: :cascade do |t|
    t.string "name"
    t.string "permalink"
    t.text "description"
  end

  create_table "profile_rights", id: false, force: :cascade do |t|
    t.integer "profile_id"
    t.integer "right_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "label"
    t.string "nicename"
    t.text "modules"
  end

  create_table "redirections", force: :cascade do |t|
    t.integer "content_id"
    t.integer "redirect_id"
    t.string "from_path"
    t.string "to_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["content_id"], name: "index_redirections_on_content_id"
  end

  create_table "redirects", force: :cascade do |t|
    t.string "from_path"
    t.string "to_path"
    t.integer "blog_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "resources", force: :cascade do |t|
    t.integer "size"
    t.string "upload"
    t.string "mime"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "article_id"
    t.boolean "itunes_metadata"
    t.string "itunes_author"
    t.string "itunes_subtitle"
    t.integer "itunes_duration"
    t.text "itunes_summary"
    t.string "itunes_keywords"
    t.string "itunes_category"
    t.boolean "itunes_explicit"
    t.integer "blog_id"
  end

  create_table "rights", force: :cascade do |t|
    t.string "name"
    t.text "description"
  end

  create_table "sidebars", force: :cascade do |t|
    t.integer "active_position"
    t.text "config"
    t.integer "staged_position"
    t.string "type"
    t.integer "blog_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at"
    t.string "display_name"
    t.index ["name"], name: "index_tags_on_name"
  end

  create_table "text_filters", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "markup"
    t.text "filters"
    t.text "params"
  end

  create_table "triggers", force: :cascade do |t|
    t.integer "pending_item_id"
    t.string "pending_item_type"
    t.datetime "due_at"
    t.string "trigger_method"
  end

  create_table "users", force: :cascade do |t|
    t.string "login"
    t.string "password"
    t.string "email"
    t.text "name"
    t.boolean "notify_via_email", default: false
    t.boolean "notify_on_new_articles", default: false
    t.boolean "notify_on_comments", default: false
    t.integer "profile_id"
    t.string "remember_token"
    t.datetime "remember_token_expires_at"
    t.string "text_filter_id", default: ""
    t.string "state", default: "active"
    t.datetime "last_connection"
    t.text "settings"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["login"], name: "index_users_on_login", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
end

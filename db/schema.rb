# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 83) do

  create_table "bj_config", :primary_key => "bj_config_id", :force => true do |t|
    t.text "hostname"
    t.text "key"
    t.text "value"
    t.text "cast"
  end

  create_table "bj_job", :primary_key => "bj_job_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "bj_job_archive", :primary_key => "bj_job_archive_id", :force => true do |t|
    t.text     "command"
    t.text     "state"
    t.integer  "priority"
    t.text     "tag"
    t.integer  "is_restartable"
    t.text     "submitter"
    t.text     "runner"
    t.integer  "pid"
    t.datetime "submitted_at"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.datetime "archived_at"
    t.text     "env"
    t.text     "stdin"
    t.text     "stdout"
    t.text     "stderr"
    t.integer  "exit_status"
  end

  create_table "blobs", :force => true do |t|
    t.binary   "content"
    t.string   "token"
    t.integer  "bundle_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bundle_contents", :force => true do |t|
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bundles", :force => true do |t|
    t.integer  "workgroup_id"
    t.integer  "workgroup_version"
    t.datetime "created_at"
    t.integer  "process_status"
    t.datetime "sail_session_start_time"
    t.datetime "sail_session_end_time"
    t.string   "sail_curnit_uuid"
    t.string   "sail_session_uuid"
    t.boolean  "content_well_formed_xml"
    t.integer  "bundle_content_id"
    t.text     "processing_error"
    t.boolean  "has_data"
    t.datetime "sail_session_modified_time"
    t.datetime "updated_at"
    t.integer  "original_bundle_content_id"
  end

  add_index "bundles", ["workgroup_id"], :name => "sds_bundles_workgroup_id_index"
  add_index "bundles", ["workgroup_version"], :name => "sds_bundles_workgroup_version_index"
  add_index "bundles", ["sail_session_start_time"], :name => "sds_bundles_sail_session_start_time_index"

  create_table "config_versions", :force => true do |t|
    t.string   "name"
    t.float    "version"
    t.text     "template"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "key"
    t.text     "description"
  end

  create_table "curnit_maps", :force => true do |t|
    t.integer "parent_id"
    t.integer "position"
    t.string  "pod_uuid",  :limit => 36
    t.string  "title"
    t.integer "number"
    t.string  "classname"
    t.string  "type"
  end

  create_table "curnits", :force => true do |t|
    t.integer  "portal_id"
    t.string   "name",              :limit => 60,  :default => "", :null => false
    t.string   "url",               :limit => 256
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "pas_map"
    t.boolean  "always_update"
    t.string   "jar_digest"
    t.datetime "jar_last_modified"
    t.string   "uuid",              :limit => 36
    t.string   "root_pod_uuid",     :limit => 36
    t.string   "title"
  end

  add_index "curnits", ["portal_id"], :name => "sds_curnits_portal_id_index"

  create_table "errorbundles", :force => true do |t|
    t.integer  "offering_id"
    t.string   "comment"
    t.string   "name"
    t.string   "content_type"
    t.binary   "data"
    t.datetime "created_at"
    t.string   "ip_address"
    t.datetime "updated_at"
  end

  create_table "jnlps", :force => true do |t|
    t.integer  "portal_id"
    t.string   "name",              :limit => 60,  :default => "", :null => false
    t.string   "url",               :limit => 256
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.boolean  "always_update"
    t.datetime "last_modified"
    t.string   "filename"
    t.integer  "config_version_id"
  end

  add_index "jnlps", ["portal_id"], :name => "sds_jnlps_portal_id_index"

  create_table "log_bundles", :force => true do |t|
    t.integer  "bundle_id"
    t.integer  "workgroup_id"
    t.string   "sail_session_uuid", :limit => 36
    t.string   "sail_curnit_uuid",  :limit => 3
    t.text     "content"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "log_bundles", ["bundle_id"], :name => "index_log_bundles_on_bundle_id"
  add_index "log_bundles", ["workgroup_id"], :name => "index_log_bundles_on_workgroup_id"
  add_index "log_bundles", ["sail_session_uuid"], :name => "index_log_bundles_on_sail_session_uuid"
  add_index "log_bundles", ["sail_curnit_uuid"], :name => "index_log_bundles_on_sail_curnit_uuid"

  create_table "notification_listeners", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.string   "url"
    t.integer  "notification_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notification_listeners", ["notification_type_id"], :name => "index_notification_listeners_on_notification_type_id"
  add_index "notification_listeners", ["url"], :name => "index_notification_listeners_on_url"

  create_table "notification_scopes", :force => true do |t|
    t.integer  "notifier_id"
    t.string   "notifier_type"
    t.integer  "notification_listener_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notification_scopes", ["notifier_id"], :name => "index_notification_scopes_on_notifier_id"
  add_index "notification_scopes", ["notification_listener_id"], :name => "index_notification_scopes_on_notification_listener_id"

  create_table "notification_types", :force => true do |t|
    t.string   "name"
    t.string   "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "script"
    t.string   "key"
  end

  add_index "notification_types", ["name"], :name => "index_notification_types_on_name"
  add_index "notification_types", ["key"], :name => "index_notification_types_on_key"

  create_table "offerings", :force => true do |t|
    t.integer  "portal_id"
    t.integer  "curnit_id"
    t.integer  "jnlp_id"
    t.string   "name",           :limit => 60, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "open_offering"
    t.datetime "close_offering"
  end

  add_index "offerings", ["portal_id"], :name => "sds_offerings_portal_id_index"
  add_index "offerings", ["curnit_id"], :name => "sds_offerings_curnit_id_index"
  add_index "offerings", ["jnlp_id"], :name => "sds_offerings_jnlp_id_index"

  create_table "offerings_attributes", :force => true do |t|
    t.integer "offering_id"
    t.text    "name",        :null => false
    t.text    "value"
  end

  add_index "offerings_attributes", ["offering_id"], :name => "sds_offerings_attributes_offering_id_index"

  create_table "pas_computational_input_values", :force => true do |t|
    t.integer "model_activity_modelrun_id"
    t.integer "computational_input_id"
    t.text    "value"
    t.float   "time"
  end

  add_index "pas_computational_input_values", ["model_activity_modelrun_id"], :name => "civ_model_activity_modelrun_id_index"
  add_index "pas_computational_input_values", ["computational_input_id"], :name => "computational_input_id_index"

  create_table "pas_computational_inputs", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.string  "name"
    t.string  "units"
    t.float   "range_max"
    t.float   "range_min"
    t.text    "uuid"
  end

  add_index "pas_computational_inputs", ["model_activity_dataset_id"], :name => "ci_model_activity_dataset_id_index"

  create_table "pas_findings", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.integer "sequence"
    t.string  "evidence"
    t.string  "text"
  end

  add_index "pas_findings", ["model_activity_dataset_id"], :name => "sds_pas_findings_model_activity_dataset_id_index"

  create_table "pas_model_activity_datasets", :force => true do |t|
    t.integer  "sock_id"
    t.datetime "created_at"
    t.string   "name"
    t.float    "start_time"
    t.float    "end_time"
    t.text     "content"
  end

  add_index "pas_model_activity_datasets", ["sock_id"], :name => "sock_id_index"

  create_table "pas_model_activity_modelruns", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.float   "start_time"
    t.float   "end_time"
    t.integer "trial_number"
    t.text    "trial_goal"
  end

  add_index "pas_model_activity_modelruns", ["model_activity_dataset_id"], :name => "mr_model_activity_dataset_id_index"

  create_table "pas_representational_attributes", :force => true do |t|
    t.integer "representational_type_id"
    t.string  "value"
  end

  add_index "pas_representational_attributes", ["representational_type_id"], :name => "representational_type_id_index"

  create_table "pas_representational_types", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.string  "name"
    t.text    "uuid"
  end

  add_index "pas_representational_types", ["model_activity_dataset_id"], :name => "rt_model_activity_dataset_id_index"

  create_table "pas_representational_values", :force => true do |t|
    t.integer "model_activity_modelrun_id"
    t.integer "representational_attribute_id"
    t.float   "time"
  end

  add_index "pas_representational_values", ["model_activity_modelrun_id"], :name => "rv_model_activity_modelrun_id_index"
  add_index "pas_representational_values", ["representational_attribute_id"], :name => "representational_attribute_id_index"

  create_table "pods", :force => true do |t|
    t.integer  "curnit_id"
    t.string   "uuid",       :limit => 36
    t.string   "rim_name"
    t.string   "rim_shape"
    t.text     "html_body"
    t.string   "mime_type"
    t.string   "encoding"
    t.string   "pas_type"
    t.string   "extension"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "pods", ["curnit_id"], :name => "sds_pods_curnit_id_index"
  add_index "pods", ["uuid"], :name => "sds_pods_uuid_index"
  add_index "pods", ["rim_name"], :name => "sds_pods_rim_name_index"

  create_table "portal_urls", :force => true do |t|
    t.integer "portal_id"
    t.string  "name",      :limit => 60,  :default => "", :null => false
    t.string  "url",       :limit => 120, :default => "", :null => false
  end

  create_table "portals", :force => true do |t|
    t.string   "name",               :default => "", :null => false
    t.boolean  "use_authentication"
    t.string   "auth_username"
    t.string   "auth_password"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "title"
    t.string   "vendor"
    t.string   "home_page_url"
    t.string   "description"
    t.string   "image_url"
    t.boolean  "last_bundle_only"
  end

  create_table "rims", :force => true do |t|
    t.integer  "pod_id"
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "roles", :force => true do |t|
    t.string  "title"
    t.integer "position"
  end

  create_table "roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "user_id"
  end

  add_index "roles_users", ["role_id", "user_id"], :name => "role_user_index"

  create_table "sail_users", :force => true do |t|
    t.integer  "portal_id"
    t.string   "first_name", :limit => 60, :default => "", :null => false
    t.string   "last_name",  :limit => 60, :default => "", :null => false
    t.string   "uuid",       :limit => 36, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sessions", ["session_id"], :name => "sds_sessions_session_id_index"

  create_table "socks", :force => true do |t|
    t.datetime "created_at"
    t.integer  "ms_offset"
    t.text     "value"
    t.integer  "bundle_id"
    t.integer  "pod_id"
    t.boolean  "duplicate"
    t.datetime "updated_at"
  end

  add_index "socks", ["bundle_id"], :name => "sds_socks_bundle_id_index"
  add_index "socks", ["pod_id"], :name => "sds_socks_pod_id_index"

  create_table "users", :force => true do |t|
    t.string   "login"
    t.string   "email"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "password_hash"
    t.string   "crypted_password",          :limit => 40
    t.string   "salt",                      :limit => 40
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.string   "activation_code",           :limit => 40
    t.datetime "activated_at"
    t.boolean  "change_password"
  end

  create_table "workgroup_memberships", :force => true do |t|
    t.integer "sail_user_id"
    t.integer "workgroup_id", :default => 0, :null => false
    t.integer "version",      :default => 0, :null => false
  end

  add_index "workgroup_memberships", ["sail_user_id"], :name => "sds_workgroup_memberships_user_id_index"
  add_index "workgroup_memberships", ["workgroup_id"], :name => "sds_workgroup_memberships_workgroup_id_index"

  create_table "workgroups", :force => true do |t|
    t.integer  "portal_id"
    t.integer  "offering_id"
    t.string   "name",        :limit => 60, :default => "", :null => false
    t.string   "uuid",        :limit => 36, :default => "", :null => false
    t.integer  "version",                   :default => 0,  :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workgroups", ["offering_id"], :name => "sds_workgroups_offering_id_index"
  add_index "workgroups", ["portal_id"], :name => "sds_workgroups_portal_id_index"

end

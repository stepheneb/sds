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

ActiveRecord::Schema.define() do

  create_table "sds_bundle_contents", :force => true do |t|
    t.text "content"
  end

  create_table "sds_bundles", :force => true do |t|
    t.integer  "workgroup_id"
    t.integer  "workgroup_version"
    t.text     "content"
    t.datetime "created_at"
    t.integer  "process_status"
    t.datetime "sail_session_start_time"
    t.datetime "sail_session_end_time"
    t.string   "sail_curnit_uuid"
    t.string   "sail_session_uuid"
    t.integer  "bundle_content_id"
    t.text     "processing_error"
  end

  add_index "sds_bundles", ["workgroup_id"], :name => "index_sds_bundles_on_workgroup_id"
  add_index "sds_bundles", ["workgroup_version"], :name => "index_sds_bundles_on_workgroup_version"

  create_table "sds_curnit_maps", :force => true do |t|
    t.integer "parent_id"
    t.integer "position"
    t.string  "pod_uuid",  :limit => 36
    t.string  "title"
    t.integer "number"
    t.string  "classname"
    t.string  "type"
  end

  create_table "sds_curnits", :force => true do |t|
    t.integer  "portal_id"
    t.string   "name",              :limit => 60,  :default => "", :null => false
    t.string   "url",               :limit => 256, :default => "", :null => false
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

  add_index "sds_curnits", ["portal_id"], :name => "index_sds_curnits_on_portal_id"

  create_table "sds_errorbundles", :force => true do |t|
    t.integer  "offering_id"
    t.string   "comment"
    t.string   "name"
    t.string   "content_type"
    t.binary   "data"
    t.datetime "created_at"
    t.string   "ip_address"
  end

  create_table "sds_jnlps", :force => true do |t|
    t.integer  "portal_id"
    t.string   "name",          :limit => 60,  :default => "", :null => false
    t.string   "url",           :limit => 256, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "body"
    t.boolean  "always_update"
    t.datetime "last_modified"
    t.string   "filename"
  end

  add_index "sds_jnlps", ["portal_id"], :name => "index_sds_jnlps_on_portal_id"

  create_table "sds_offerings", :force => true do |t|
    t.integer  "portal_id"
    t.integer  "curnit_id"
    t.integer  "jnlp_id"
    t.string   "name",           :limit => 60, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "open_offering"
    t.datetime "close_offering"
  end

  add_index "sds_offerings", ["portal_id"], :name => "index_sds_offerings_on_portal_id"
  add_index "sds_offerings", ["curnit_id"], :name => "index_sds_offerings_on_curnit_id"
  add_index "sds_offerings", ["jnlp_id"], :name => "index_sds_offerings_on_jnlp_id"

  create_table "sds_offerings_attributes", :force => true do |t|
    t.integer "offering_id"
    t.text    "name",        :default => "", :null => false
    t.text    "value"
  end

  add_index "sds_offerings_attributes", ["offering_id"], :name => "index_sds_offerings_attributes_on_offering_id"

  create_table "sds_pas_computational_input_values", :force => true do |t|
    t.integer "model_activity_modelrun_id"
    t.integer "computational_input_id"
    t.text    "value"
    t.float   "time"
  end

  add_index "sds_pas_computational_input_values", ["model_activity_modelrun_id"], :name => "civ_model_activity_modelrun_id_index"
  add_index "sds_pas_computational_input_values", ["computational_input_id"], :name => "computational_input_id_index"

  create_table "sds_pas_computational_inputs", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.string  "name"
    t.string  "units"
    t.float   "range_max"
    t.float   "range_min"
  end

  add_index "sds_pas_computational_inputs", ["model_activity_dataset_id"], :name => "ci_model_activity_dataset_id_index"

  create_table "sds_pas_findings", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.integer "sequence"
    t.string  "evidence"
    t.string  "text"
  end

  add_index "sds_pas_findings", ["model_activity_dataset_id"], :name => "index_sds_pas_findings_on_model_activity_dataset_id"

  create_table "sds_pas_model_activity_datasets", :force => true do |t|
    t.integer  "sock_id"
    t.datetime "created_at"
    t.string   "name"
    t.float    "start_time"
    t.float    "end_time"
  end

  add_index "sds_pas_model_activity_datasets", ["sock_id"], :name => "sock_id_index"

  create_table "sds_pas_model_activity_modelruns", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.float   "start_time"
    t.float   "end_time"
    t.integer "trial_number"
    t.text    "trial_goal"
  end

  add_index "sds_pas_model_activity_modelruns", ["model_activity_dataset_id"], :name => "mr_model_activity_dataset_id_index"

  create_table "sds_pas_representational_attributes", :force => true do |t|
    t.integer "representational_type_id"
    t.string  "value"
  end

  add_index "sds_pas_representational_attributes", ["representational_type_id"], :name => "representational_type_id_index"

  create_table "sds_pas_representational_types", :force => true do |t|
    t.integer "model_activity_dataset_id"
    t.string  "name"
  end

  add_index "sds_pas_representational_types", ["model_activity_dataset_id"], :name => "rt_model_activity_dataset_id_index"

  create_table "sds_pas_representational_values", :force => true do |t|
    t.integer "model_activity_modelrun_id"
    t.integer "representational_attribute_id"
    t.float   "time"
  end

  add_index "sds_pas_representational_values", ["model_activity_modelrun_id"], :name => "rv_model_activity_modelrun_id_index"
  add_index "sds_pas_representational_values", ["representational_attribute_id"], :name => "representational_attribute_id_index"

  create_table "sds_pods", :force => true do |t|
    t.integer "curnit_id"
    t.string  "uuid",      :limit => 36
    t.string  "rim_name"
    t.string  "rim_shape"
    t.text    "html_body"
    t.string  "mime_type"
    t.string  "encoding"
    t.string  "pas_type"
    t.string  "extension"
  end

  add_index "sds_pods", ["curnit_id"], :name => "index_sds_pods_on_curnit_id"
  add_index "sds_pods", ["uuid"], :name => "index_sds_pods_on_uuid"
  add_index "sds_pods", ["rim_name"], :name => "index_sds_pods_on_rim_name"

  create_table "sds_portal_urls", :force => true do |t|
    t.integer "portal_id"
    t.string  "name",      :limit => 60,  :default => "", :null => false
    t.string  "url",       :limit => 120, :default => "", :null => false
  end

  create_table "sds_portals", :force => true do |t|
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

  create_table "sds_rims", :force => true do |t|
    t.integer "pod_id"
    t.string  "name"
  end

  create_table "sds_roles", :force => true do |t|
    t.string "title"
  end

  create_table "sds_roles_users", :id => false, :force => true do |t|
    t.integer "role_id"
    t.integer "sds_user_id"
  end

  create_table "sds_sail_users", :force => true do |t|
    t.integer  "portal_id"
    t.string   "first_name", :limit => 60, :default => "", :null => false
    t.string   "last_name",  :limit => 60, :default => "", :null => false
    t.string   "uuid",       :limit => 36, :default => "", :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "sds_schema_info", :id => false, :force => true do |t|
    t.integer "version"
  end

  create_table "sds_sessions", :force => true do |t|
    t.string   "session_id"
    t.text     "data"
    t.datetime "updated_at"
  end

  add_index "sds_sessions", ["session_id"], :name => "index_sds_sessions_on_session_id"

  create_table "sds_socks", :force => true do |t|
    t.datetime "created_at"
    t.integer  "ms_offset"
    t.text     "value"
    t.integer  "bundle_id"
    t.integer  "pod_id"
    t.boolean  "duplicate"
  end

  add_index "sds_socks", ["bundle_id"], :name => "index_sds_socks_on_bundle_id"
  add_index "sds_socks", ["pod_id"], :name => "index_sds_socks_on_pod_id"

  create_table "sds_users", :force => true do |t|
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
  end

  create_table "sds_workgroup_memberships", :force => true do |t|
    t.integer "sail_user_id", :null => false
    t.integer "workgroup_id", :null => false
    t.integer "version",      :null => false
  end

  add_index "sds_workgroup_memberships", ["sail_user_id"], :name => "index_sds_workgroup_memberships_on_sail_user_id"
  add_index "sds_workgroup_memberships", ["workgroup_id"], :name => "index_sds_workgroup_memberships_on_workgroup_id"

  create_table "sds_workgroups", :force => true do |t|
    t.integer  "portal_id"
    t.integer  "offering_id"
    t.string   "name",        :limit => 60, :default => "", :null => false
    t.string   "uuid",        :limit => 36, :default => "", :null => false
    t.integer  "version",                                   :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sds_workgroups", ["offering_id"], :name => "index_sds_workgroups_on_offering_id"
  add_index "sds_workgroups", ["portal_id"], :name => "index_sds_workgroups_on_portal_id"

end

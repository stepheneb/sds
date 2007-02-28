class AddBundleJnlpAndCurnitAttributes < ActiveRecord::Migration
  def self.up
    remove_column :sds_bundles, :offering_id

    add_column :sds_bundles, :sail_session_start_time, :datetime
    add_column :sds_bundles, :sail_session_end_time, :datetime
    add_column :sds_bundles, :sail_curnit_uuid, :string
    add_column :sds_bundles, :sail_session_uuid, :string
    add_column :sds_pods, :html_body, :text

    add_column :sds_jnlps, :body, :text
    add_column :sds_jnlps, :always_update, :boolean
    add_column :sds_jnlps, :last_modified, :datetime
    add_column :sds_jnlps, :filename, :string

    add_column :sds_curnits, :pas_map, :text
    add_column :sds_curnits, :always_update, :boolean
    add_column :sds_curnits, :jar_digest, :string
    add_column :sds_curnits, :jar_last_modified, :datetime
    add_column :sds_curnits, :filename, :string
  end

  def self.down
    add_column :sds_bundles, :offering_id, :integer

    remove_column :sds_bundles, :sail_session_start_time
    remove_column :sds_bundles, :sail_session_end_time
    remove_column :sds_bundles, :sail_curnit_uuid
    remove_column :sds_bundles, :sail_session_uuid

    remove_column :sds_pods, :html_body

    remove_column :sds_jnlps, :body
    remove_column :sds_jnlps, :last_modified
    remove_column :sds_jnlps, :always_update
    remove_column :sds_jnlps, :filename

    remove_column :sds_curnits, :pas_map
    remove_column :sds_curnits, :always_update
    remove_column :sds_curnits, :jar_digest
    remove_column :sds_curnits, :jar_last_modified
    remove_column :sds_curnits, :filename
  end
end

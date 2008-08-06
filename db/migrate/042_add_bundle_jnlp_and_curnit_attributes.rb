class AddBundleJnlpAndCurnitAttributes < ActiveRecord::Migration
  def self.up
    remove_column "bundles", :offering_id

    add_column "bundles", :sail_session_start_time, :datetime
    add_column "bundles", :sail_session_end_time, :datetime
    add_column "bundles", :sail_curnit_uuid, :string
    add_column "bundles", :sail_session_uuid, :string
    add_column "pods", :html_body, :text

    add_column "jnlps", :body, :text
    add_column "jnlps", :always_update, :boolean
    add_column "jnlps", :last_modified, :datetime
    add_column "jnlps", :filename, :string

    add_column "curnits", :pas_map, :text
    add_column "curnits", :always_update, :boolean
    add_column "curnits", :jar_digest, :string
    add_column "curnits", :jar_last_modified, :datetime
    add_column "curnits", :filename, :string
  end

  def self.down
    add_column "bundles", :offering_id, :integer

    remove_column "bundles", :sail_session_start_time
    remove_column "bundles", :sail_session_end_time
    remove_column "bundles", :sail_curnit_uuid
    remove_column "bundles", :sail_session_uuid

    remove_column "pods", :html_body

    remove_column "jnlps", :body
    remove_column "jnlps", :last_modified
    remove_column "jnlps", :always_update
    remove_column "jnlps", :filename

    remove_column "curnits", :pas_map
    remove_column "curnits", :always_update
    remove_column "curnits", :jar_digest
    remove_column "curnits", :jar_last_modified
    remove_column "curnits", :filename
  end
end

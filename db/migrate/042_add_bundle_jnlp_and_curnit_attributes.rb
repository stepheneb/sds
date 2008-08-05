class AddBundleJnlpAndCurnitAttributes < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :offering_id

    add_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_session_start_time, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_session_end_time, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_curnit_uuid, :string
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_session_uuid, :string
    add_column "#{RAILS_DATABASE_PREFIX}pods", :html_body, :text

    add_column "#{RAILS_DATABASE_PREFIX}jnlps", :body, :text
    add_column "#{RAILS_DATABASE_PREFIX}jnlps", :always_update, :boolean
    add_column "#{RAILS_DATABASE_PREFIX}jnlps", :last_modified, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}jnlps", :filename, :string

    add_column "#{RAILS_DATABASE_PREFIX}curnits", :pas_map, :text
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :always_update, :boolean
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :jar_digest, :string
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :jar_last_modified, :datetime
    add_column "#{RAILS_DATABASE_PREFIX}curnits", :filename, :string
  end

  def self.down
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :offering_id, :integer

    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_session_start_time
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_session_end_time
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_curnit_uuid
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :sail_session_uuid

    remove_column "#{RAILS_DATABASE_PREFIX}pods", :html_body

    remove_column "#{RAILS_DATABASE_PREFIX}jnlps", :body
    remove_column "#{RAILS_DATABASE_PREFIX}jnlps", :last_modified
    remove_column "#{RAILS_DATABASE_PREFIX}jnlps", :always_update
    remove_column "#{RAILS_DATABASE_PREFIX}jnlps", :filename

    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :pas_map
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :always_update
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :jar_digest
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :jar_last_modified
    remove_column "#{RAILS_DATABASE_PREFIX}curnits", :filename
  end
end

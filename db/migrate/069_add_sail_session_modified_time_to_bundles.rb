class AddSailSessionModifiedTimeToBundles < ActiveRecord::Migration
  def self.up
    add_column :sds_bundles, :sail_session_modified_time, :datetime
    puts "\nDON'T FORGET TO RUN 'rake sds:create_sail_session_attributes' to rebuild the sail_session times!"
  end

  def self.down
    remove_column :sds_bundles, :sail_session_modified_time
  end
end

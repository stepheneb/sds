class RemovePortalOfferingAssociations < ActiveRecord::Migration
  def self.up
    remove_column "#{RAILS_DATABASE_PREFIX}log_bundles", :portal_id
    remove_column "#{RAILS_DATABASE_PREFIX}log_bundles", :offering_id
  end

  def self.down
      add_column "#{RAILS_DATABASE_PREFIX}log_bundles", :portal_id, :integer
      add_column "#{RAILS_DATABASE_PREFIX}log_bundles", :offering_id, :integer
  end
end

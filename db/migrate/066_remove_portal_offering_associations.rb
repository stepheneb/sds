class RemovePortalOfferingAssociations < ActiveRecord::Migration
  def self.up
    remove_column "log_bundles", :portal_id
    remove_column "log_bundles", :offering_id
  end

  def self.down
      add_column "log_bundles", :portal_id, :integer
      add_column "log_bundles", :offering_id, :integer
  end
end

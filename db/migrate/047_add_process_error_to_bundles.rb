class AddProcessErrorToBundles < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}bundles", :processing_error, :text
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}bundles", :processing_error
  end
end

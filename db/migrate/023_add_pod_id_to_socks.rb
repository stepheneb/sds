class AddPodIdToSocks < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}socks", :pod_id, :integer
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}socks", :pod_id  
  end
end

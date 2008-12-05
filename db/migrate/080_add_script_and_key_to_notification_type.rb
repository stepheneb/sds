class AddScriptAndKeyToNotificationType < ActiveRecord::Migration
  def self.up
    add_column :notification_types, :script, :text
    add_column :notification_types, :key, :string
    
    add_index :notification_types, :key
  end

  def self.down
    remove_column :notification_types, :script
    remove_column :notification_types, :key
  end
end

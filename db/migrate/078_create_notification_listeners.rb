class CreateNotificationListeners < ActiveRecord::Migration
  def self.up
    create_table :notification_listeners do |t|
      t.string "name"
      t.string "description"
      t.string "url"
      t.integer "notification_type_id"
      t.timestamps
    end
    
    add_index :notification_listeners, :notification_type_id
    add_index :notification_listeners, :url
  end

  def self.down
    drop_table :notification_listeners
  end
end

class CreateNotificationTypes < ActiveRecord::Migration
  def self.up
    create_table :notification_types do |t|
      t.string "name"
      t.string "description"
      t.timestamps
    end
    
    add_index :notification_types, :name
  end

  def self.down
    drop_table :notification_types
  end
end

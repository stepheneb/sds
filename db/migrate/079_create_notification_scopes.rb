class CreateNotificationScopes < ActiveRecord::Migration
  def self.up
    create_table :notification_scopes do |t|
      t.integer :notifier_id
      t.string :notifier_type
      t.integer :notification_listener_id
      t.timestamps
    end
    add_index :notification_scopes, :notifier_id
    add_index :notification_scopes, :notification_listener_id
  end

  def self.down
    drop_table :notification_scopes
  end
end

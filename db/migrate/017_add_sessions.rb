class AddSessions < ActiveRecord::Migration
# see environment.rb CGI::Session::ActiveRecordStore::Session.table_name = 'sds_sessions'
  def self.up
    create_table :sds_sessions do |t|
      t.column :session_id, :string
      t.column :data, :text
      t.column :updated_at, :datetime
    end
    
    add_index :sds_sessions, :session_id
  end

  def self.down
    drop_table :sds_sessions
  end
end

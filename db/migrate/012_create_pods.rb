class CreatePods < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}pods" do |t|
      t.column :curnit_id, :integer
      t.column :uuid, :string, :limit => 36
    end
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}pods"
  end
end

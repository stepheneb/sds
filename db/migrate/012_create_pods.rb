class CreatePods < ActiveRecord::Migration
  def self.up
    create_table "pods" do |t|
      t.column :curnit_id, :integer
      t.column :uuid, :string, :limit => 36
    end
  end

  def self.down
    drop_table "pods"
  end
end

class CreateRims < ActiveRecord::Migration
  def self.up
    create_table "rims" do |t|
      t.column :pod_id, :integer
      t.column :name, :string
    end
  end

  def self.down
    drop_table "rims"
  end
end

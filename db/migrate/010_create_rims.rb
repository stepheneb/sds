class CreateRims < ActiveRecord::Migration
  def self.up
    create_table :sds_rims do |t|
      t.column :pod_id, :integer
      t.column :name, :string
    end
  end

  def self.down
    drop_table :sds_rims
  end
end

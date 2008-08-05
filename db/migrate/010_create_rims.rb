class CreateRims < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}rims" do |t|
      t.column :pod_id, :integer
      t.column :name, :string
    end
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}rims"
  end
end

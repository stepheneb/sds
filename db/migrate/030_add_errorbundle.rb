class AddErrorbundle < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}errorbundles" do |t|
      t.column :offering_id, :integer
      t.column :comment, :string
      t.column :name, :string
      t.column :content_type, :string
      t.column :data, :binary, :limit => 4.megabyte
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}errorbundles"
  end
end

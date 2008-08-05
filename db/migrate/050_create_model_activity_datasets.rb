class CreateModelActivityDatasets < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}pas_model_activity_datasets" do |t|
      t.column :sock_id, :integer
      t.column :created_at, :timestamp
      t.column :name, :string
      t.column :start_time, :float
      t.column :end_time, :float
    end
    add_index "#{RAILS_DATABASE_PREFIX}pas_model_activity_datasets", :sock_id, :name => "sock_id_index"
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}pas_model_activity_datasets"
  end
end

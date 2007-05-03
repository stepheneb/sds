class CreateModelActivityDatasets < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_model_activity_datasets do |t|
      t.column :sock_id, :integer
      t.column :created_at, :timestamp
      t.column :name, :string
      t.column :start_time, :double
      t.column :end_time, :double
    end
  end

  def self.down
    drop_table :sds_pas_model_activity_datasets
  end
end

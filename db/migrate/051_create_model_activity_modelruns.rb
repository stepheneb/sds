class CreateModelActivityModelruns < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_model_activity_modelruns do |t|
      t.column :model_activity_dataset_id, :integer
      t.column :start_time, :double
      t.column :end_time, :double
    end
  end

  def self.down
    drop_table :sds_pas_model_activity_modelruns
  end
end

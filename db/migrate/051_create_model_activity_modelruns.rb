class CreateModelActivityModelruns < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_model_activity_modelruns do |t|
      t.column :model_activity_dataset_id, :integer
      t.column :start_time, :float
      t.column :end_time, :float
    end
    add_index :sds_pas_model_activity_modelruns, :model_activity_dataset_id, :name => "mr_model_activity_dataset_id_index"
  end

  def self.down
    drop_table :sds_pas_model_activity_modelruns
  end
end

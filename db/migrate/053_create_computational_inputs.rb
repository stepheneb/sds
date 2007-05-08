class CreateComputationalInputs < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_computational_inputs do |t|
      t.column :model_activity_dataset_id, :integer
      t.column :name, :string
      t.column :units, :string
      t.column :range_max, :float
      t.column :range_min, :float
    end
    add_index :sds_pas_computational_inputs, :model_activity_dataset_id, :name => "ci_model_activity_dataset_id_index"
  end

  def self.down
    drop_table :sds_pas_computational_inputs
  end
end

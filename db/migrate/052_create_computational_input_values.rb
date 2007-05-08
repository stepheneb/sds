class CreateComputationalInputValues < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_computational_input_values do |t|
      t.column :model_activity_modelrun_id, :integer
      t.column :computational_input_id, :integer
      t.column :value, :text
      t.column :time, :double
    end
    add_index :sds_pas_computational_input_values, :model_activity_modelrun_id, :name => "civ_model_activity_modelrun_id_index"
    add_index :sds_pas_computational_input_values, :computational_input_id, :name => "computational_input_id_index"
  end

  def self.down
    drop_table :sds_pas_computational_input_values
  end
end
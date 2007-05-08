class CreateRepresentationalValues < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_representational_values do |t|
      t.column :model_activity_modelrun_id, :integer
      t.column :representational_attribute_id, :integer
      t.column :time, :double
    end
    add_index :sds_pas_representational_values, :model_activity_modelrun_id, :name => "rv_model_activity_modelrun_id_index"
    add_index :sds_pas_representational_values, :representational_attribute_id, :name => "representational_attribute_id_index"
  end

  def self.down
    drop_table :sds_pas_representational_values
  end
end

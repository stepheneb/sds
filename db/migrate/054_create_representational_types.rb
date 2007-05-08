class CreateRepresentationalTypes < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_representational_types do |t|
      t.column :model_activity_dataset_id, :integer
      t.column :name, :string
    end
    add_index :sds_pas_representational_types, :model_activity_dataset_id, :name => "rt_model_activity_dataset_id_index"
  end

  def self.down
    drop_table :sds_pas_representational_types
  end
end

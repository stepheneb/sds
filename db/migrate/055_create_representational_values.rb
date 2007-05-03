class CreateRepresentationalValues < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_representational_values do |t|
      t.column :model_activity_modelrun_id, :integer
      t.column :representational_attribute_id, :integer
      t.column :time, :double
    end
  end

  def self.down
    drop_table :sds_pas_representational_values
  end
end

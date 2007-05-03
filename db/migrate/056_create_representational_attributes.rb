class CreateRepresentationalAttributes < ActiveRecord::Migration
  def self.up
    create_table :sds_pas_representational_attributes do |t|
      t.column :representational_type_id, :integer
      t.column :value, :string
    end
  end

  def self.down
    drop_table :sds_pas_representational_attributes
  end
end

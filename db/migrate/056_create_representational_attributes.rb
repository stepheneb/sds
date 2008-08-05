class CreateRepresentationalAttributes < ActiveRecord::Migration
  def self.up
    create_table "#{RAILS_DATABASE_PREFIX}pas_representational_attributes" do |t|
      t.column :representational_type_id, :integer
      t.column :value, :string
    end
    add_index "#{RAILS_DATABASE_PREFIX}pas_representational_attributes", :representational_type_id, :name => "representational_type_id_index"
  end

  def self.down
    drop_table "#{RAILS_DATABASE_PREFIX}pas_representational_attributes"
  end
end

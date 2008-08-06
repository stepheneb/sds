class CreatePasFindings < ActiveRecord::Migration
  def self.up
    create_table 'pas_findings' do |t|
      t.column :model_activity_dataset_id, :int
      t.column :sequence, :integer
      t.column :evidence, :string
      t.column :text, :string
    end
    add_index "pas_findings", :model_activity_dataset_id
  end

  def self.down
    remove_index "pas_findings", :model_activity_dataset_id
    drop_table 'pas_findings'
  end
end

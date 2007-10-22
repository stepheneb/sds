class CreatePasFindings < ActiveRecord::Migration
  def self.up
    create_table 'sds_pas_findings' do |t|
      t.column :model_activity_dataset_id, :int
      t.column :sequence, :integer
      t.column :evidence, :string
      t.column :text, :string
    end
    add_index :sds_pas_findings, :model_activity_dataset_id
  end

  def self.down
    remove_index :sds_pas_findings, :model_activity_dataset_id
    drop_table 'sds_pas_findings'
  end
end

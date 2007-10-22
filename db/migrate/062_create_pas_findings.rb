class CreatePasFindings < ActiveRecord::Migration
  def self.up
    create_table 'sds_pas_findings' do |t|
      t.column :model_activity_dataset_id, :int
      t.column :sequence, :integer
      t.column :evidence, :string
      t.column :text, :string
    end
  end

  def self.down
    drop_table 'sds_pas_findings'
  end
end

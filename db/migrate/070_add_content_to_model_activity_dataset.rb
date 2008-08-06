class AddContentToModelActivityDataset < ActiveRecord::Migration
  def self.up
    add_column "pas_model_activity_datasets", :content, :text, :limit => 2097151
    add_column "pas_computational_inputs", :uuid, :text
    add_column "pas_representational_types", :uuid, :text
    puts "\nDON'T FORGET TO RUN 'rake sds:rebuild_mad' to rebuild the model activity datasets!"
  end

  def self.down
    remove_column "pas_model_activity_datasets", :content
    remove_column "pas_computational_inputs", :uuid
    remove_column "pas_representational_types", :uuid
  end
end

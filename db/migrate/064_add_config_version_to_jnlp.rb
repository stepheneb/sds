class AddConfigVersionToJnlp < ActiveRecord::Migration
  def self.up
    add_column :sds_jnlps, :config_version_id, :integer
  end

  def self.down
    remove_column :sds_jnlps, :config_version_id
  end
end

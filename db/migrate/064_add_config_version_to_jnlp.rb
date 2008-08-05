class AddConfigVersionToJnlp < ActiveRecord::Migration
  def self.up
    add_column "#{RAILS_DATABASE_PREFIX}jnlps", :config_version_id, :integer
  end

  def self.down
    remove_column "#{RAILS_DATABASE_PREFIX}jnlps", :config_version_id
  end
end

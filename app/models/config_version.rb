class ConfigVersion < ActiveRecord::Base
  set_table_name "#{RAILS_DATABASE_PREFIX}config_versions"
  
  has_many :jnlp
  
  validates_presence_of :key
  validates_uniqueness_of :key

  before_save :verify_valid_template
  
  def verify_valid_template
    begin
      # TODO how do we verify we have a valid template?
      # most templates will rely on externally set variables, which aren't going to be set here
      # so a straight eval won't work. Is there a way to parse it just to check if it's well-formed?
      # result = eval(self.template)
    rescue Exception => e
      raise "Invalid template #{e}"
    end
  end
end

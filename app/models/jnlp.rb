class Jnlp < ActiveRecord::Base
  
  set_table_name "sds_jnlps"
  
  validates_presence_of :name, :url

  belongs_to :portal
  has_many :offerings

  def self.find_all_in_portal(pid)
    Jnlp.find(:all, :conditions => ["portal_id = ?", pid])
  end
    
end
  
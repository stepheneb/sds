class Offering < ActiveRecord::Base
  
  set_table_name "sds_offerings"
  
  validates_presence_of :curnit_id, :jnlp_id, :name
  
  belongs_to :portal
  belongs_to :curnit
  belongs_to :jnlp
  has_many :workgroups
  has_and_belongs_to_many :users, options = { :join_table => 'sds_offerings_users'}

  def self.find_all_in_portal(pid)
    Offering.find(:all, :order => "created_at DESC", :conditions => ["portal_id = ?", pid])
  end
  
end

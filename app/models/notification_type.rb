class NotificationType < ActiveRecord::Base
  
  validates_presence_of :name
  validates_uniqueness_of :name
  validates_uniqueness_of :key
  
  has_many :notification_listeners
  
  def self.search(search, page)
      paginate :per_page => 20, :page => page,
               :conditions => ['name like ? OR description like ?',"%#{search}%", "%#{search}%"], :order => 'created_at DESC'
    end
end

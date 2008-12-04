class NotificationListener < ActiveRecord::Base
  
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  
  # make sure that the same url can only be used once per type
  validates_uniqueness_of :url, :scope => :notification_type_id
  
  belongs_to :notification_type
  
  def self.search(search, page)
      paginate :per_page => 20, :page => page,
               :conditions => ['name like ? OR description like ?',"%#{search}%", "%#{search}%"], :order => 'created_at DESC'
    end
end

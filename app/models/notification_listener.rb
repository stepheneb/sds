class NotificationListener < ActiveRecord::Base
  
  validates_presence_of :name, :url
  validates_uniqueness_of :name
  
  # make sure that the same url can only be used once per type
  validates_uniqueness_of :url, :scope => :notification_type_id
  
  belongs_to :notification_type
  has_many :notification_scopes
  
  def self.search(search, page)
      paginate :per_page => 20, :page => page,
               :conditions => ['name like ? OR description like ?',"%#{search}%", "%#{search}%"], :order => 'created_at DESC'
    end
    
  def notifiers
    self.notification_scopes.collect { |s| s.notifier }
  end
  
  def notify(object)
    @object = object
    @url = self.url
    # eval the script associated with this notification_type. The script handles sending the information to the url
    begin
      eval(self.notification_type.script)
    rescue Exception => e
      logger.error("NotificationType script eval failed! #{e}")
    end
  end
  
  def post_data(url, hash)
    res = Net::HTTP.post_form(URI.parse(url), hash)
  end

end

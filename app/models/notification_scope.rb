class NotificationScope < ActiveRecord::Base
  belongs_to :notification_listener
  belongs_to :notifier, :polymorphic => true
  
  validates_uniqueness_of :notification_listener_id, :scope => [:notifier_id, :notifier_type], :message => "This NotificationListener is already associated with that object!"
end

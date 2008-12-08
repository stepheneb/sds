module Notifier

  def Notifier.included(mod)
    mod.class_eval do
      has_many :notification_scopes, :as => :notifier
      has_many :notification_listeners, :as => :notifier, :through => :notification_scopes do
        def by_type(type)
          find(:all).select {|nl| nl.notification_type_id == type.id}
        end
      end
    end
  end
  
  def notification_listeners_include_inherited
    self.notification_listeners | self.inherited_notification_listeners
  end
  
  def notification_listeners_include_inherited_by_type(type)
    self.notification_listeners.by_type(type) | self.inherited_notification_listeners_by_type(type)
  end
  
  def inherited_notification_listeners
    case self.class.name
      when "Workgroup"
        return self.offering.notification_listeners | self.offering.inherited_notification_listeners
      when "Offering"
        return self.portal.notification_listeners
      when "Portal"
        # find nothing, since Portal can't inherit listeners right now
        []
      else
        []
    end
  end
  
  def inherited_notification_listeners_by_type(type)
      case self.class.name
        when "Workgroup"
          return self.offering.notification_listeners.by_type(type) | self.offering.inherited_notification_listeners_by_type(type)
        when "Offering"
          return self.portal.notification_listeners.by_type(type)
        when "Portal"
          # find nothing, since Portal can't inherit listeners right now
          []
        else
          []
      end
    end
  
  def notification_listener_ids=(arr)
    # figure out what is the same, and then using that set, figure out what
    # needs to be deleted and added
    
    cur_nls = self.notification_listeners.collect{|nl| nl.id}
#    puts "cur_nls = [#{cur_nls.join(",")}]"
    same = cur_nls & arr
#    puts "same = [#{same.join(",")}]"
    to_be_deleted = cur_nls - same
#    puts "to_be_deleted = [#{to_be_deleted.join(",")}]"
    to_be_added = arr - same
#    puts "to_be_added = [#{to_be_added.join(",")}]"
    scopes = self.notification_scopes
    scopes.each do |s|
      if to_be_deleted.include? s.notification_listener_id
        s.destroy
#        puts "destroyed s: #{s}"
      end        
    end
    
    to_be_added.each do |a|
      nl = NotificationListener.find(a)
      self.notification_listeners << nl
#      puts "added nl: #{nl}"
    end
    
    # reload ourselves so the changes in associations will be accurate
    self.reload
  end
end
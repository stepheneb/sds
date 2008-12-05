class BundleObserver < ActiveRecord::Observer
  def after_create(bundle)
    # first schedule the bundle processing
    if GEM_BACKGROUND_JOB_AVAILABLE
      jobs = Bj.submit "./script/runner 'Bundle.find(#{bundle.id}).process_bundle_contents'"
    else
      bundle.process_bundle_contents
    end
    
    # then schedule the notification
    script = "bundle = Bundle.find(#{bundle.id}); type = NotificationType.find_by_key(\"bundle:create\"); listeners = bundle.workgroup.notification_listeners.by_type(type) | bundle.workgroup.offering.notification_listeners.by_type(type) | bundle.workgroup.portal.notification_listeners.by_type(type); listeners.each{|l| l.notify(bundle) }"
    # notify listeners
    if GEM_BACKGROUND_JOB_AVAILABLE
      jobs = Bj.submit "./script/runner '#{script}'"
    else
      eval(script)
    end
    
  end
end
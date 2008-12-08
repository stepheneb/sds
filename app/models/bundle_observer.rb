class BundleObserver < ActiveRecord::Observer
  def after_create(bundle)
    # first schedule the bundle processing
    if GEM_BACKGROUND_JOB_AVAILABLE
      jobs = Bj.submit "./script/runner 'Bundle.find(#{bundle.id}).process_bundle_contents'"
    else
      bundle.process_bundle_contents
    end
    
    # then schedule the notification
    script = "bundle = Bundle.find(#{bundle.id}); type = NotificationType.find_by_key(\"bundle:create\"); bundle.workgroup.notification_listeners_include_inherited_by_type(type).each{|l| l.notify(bundle) }"
    # notify listeners
    if GEM_BACKGROUND_JOB_AVAILABLE
      jobs = Bj.submit "./script/runner '#{script}'"
    else
      eval(script)
    end
    
  end
end
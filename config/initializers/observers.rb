# :user_observer triggers activation emails to be sent when a user registers, and confirmation email to be sent when they activate
# :bundle_observer triggers notifications to be sent whenever a bundle is created

ActiveRecord::Base.observers << :user_observer
ActiveRecord::Base.observers << :bundle_observer

# have to call instantiate_observers since at the point that initializers are run, the observers have already been instantiated
ActiveRecord::Base.instantiate_observers


# To enable the Exception Notifier plugin look at sample configurations in config/ and:
# 1) Create config/mailer.yml with the smtp host settings for sending mail.
# 2) Create config/exception_notifier_recipients.yml with the list of address to receive mails.
MAILER_CONFIG_EXISTS = File.exists?("#{RAILS_ROOT}/config/mailer.yml")
if MAILER_CONFIG_EXISTS
  require "action_mailer"
  EXCEPTION_NOTIFIER_CONFIGS_EXISTS = File.exists?("#{RAILS_ROOT}/config/exception_notifier_recipients.yml")
else
  EXCEPTION_NOTIFIER_CONFIGS_EXISTS = nil
end
if EXCEPTION_NOTIFIER_CONFIGS_EXISTS
  ExceptionNotifier.exception_recipients = YAML::load(IO.read("#{RAILS_ROOT}/config/exception_notifier_recipients.yml"))
  # Sender address: defaults to exception.notifier@default.com
  ExceptionNotifier.sender_address = %("[SDS ERROR]" <sds_error@concord.org>)
  # defaults to "[ERROR] "
  ExceptionNotifier.email_prefix = "[SDS ERROR] (#{RAILS_ROOT})"
end

# runs background job daemon
# gem install bj
# see: http://codeforpeople.com/lib/ruby/bj/bj-1.0.1/README
require 'bj'
GEM_BACKGROUND_JOB_AVAILABLE = true

# see: http://github.com/mislav/will_paginate/wikis/installation
require 'will_paginate'

# Time Zone things for consistent timestamps in the db
ActiveRecord::Base.default_timezone = :utc

require 'sds_init'
require 'uuidtools'
require 'b64'
require 'notifier'
require 'process_logger'

require "math/statistics"
class Array
  include Math::Statistics
end

class Time
  def self.java8601(java_date)
    Time.xmlschema("#{java_date[0..-3]}:#{java_date[-2..-1]}")
  end

  def to_java8601
    ts = self.getlocal.xmlschema(3)
    ts[0..-4]+ts[-2..-1]
  end
end

# require 'dike'
# Dike.on :rails

# :user_observer triggers activation emails to be sent when a user registers, and confirmation email to be sent when they activate
# :bundle_observer triggers notifications to be sent whenever a bundle is created

ActiveRecord::Base.observers << :user_observer
ActiveRecord::Base.observers << :bundle_observer

# have to call instantiate_observers since at the point that initializers are run, the observers have already been instantiated
ActiveRecord::Base.instantiate_observers

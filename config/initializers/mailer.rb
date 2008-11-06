# To enable email activation messages copy the file: 
#     config/mailer.sample.yml 
# to: config/mailer.yml
# and enter valid email settings.
#
# the default_url_option are used when resolving named routes
#

if (File.exists?("#{RAILS_ROOT}/config/mailer.yml"))
  mailer_settings = YAML::load(IO.read("#{RAILS_ROOT}/config/mailer.yml"))

  ActionMailer::Base.default_url_options[:host] = mailer_settings[:host]
  ActionMailer::Base.delivery_method = mailer_settings[:delivery_method]
  ActionMailer::Base.smtp_settings = mailer_settings[:smtp]
end
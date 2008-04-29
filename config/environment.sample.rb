# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.0.2' unless defined? RAILS_GEM_VERSION
USE_LIBXML = false

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

if RUBY_PLATFORM =~ /java/
   require 'rubygems'
   RAILS_CONNECTION_ADAPTERS = %w(jdbc)
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use (only works if using vendor/rails).
  # To use Rails without a database, you must remove the Active Record framework
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Only load the plugins named here, in the order given. By default, all plugins 
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random, 
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session_store = :active_record_store

  # config.action_controller.session = {
  #   :session_key => '_sds2_session',
  #   :secret      => 'c980b40a0a756cfa197d1f354ec69325b9f5d4ef4f8adbac02359e2da8359c17e626dce4fc1568f4e06c91e3bfb17d401cf215ef5edf55cc860c769c3f4f3490'
  # }

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # Disable request forgery protection for now ...
  # needs to be fixed ...
  # see: http://api.rubyonrails.org/classes/ActionController/RequestForgeryProtection/ClassMethods.html#M000300
  config.action_controller.allow_forgery_protection = false

  # This adds any Gems that may have been unpacked into vendor/gems to the load path
  # see: http://errtheblog.com/posts/50-vendor-everything
  config.load_paths += Dir["#{RAILS_ROOT}/vendor/gems/**"].map do |dir| 
    File.directory?(lib = "#{dir}/lib") ? lib : dir
  end
  
  if RUBY_PLATFORM =~ /java/
    # for the spawn plugin
    # when using threads (default) set allow_concurrency to true
    config.active_record.allow_concurrency=true
    # to use forks instead of threads, set Spawn::method :fork
    # Spawn::method :fork
  end
end

# runs background job daemon
# gem install bj
# see: http://codeforpeople.com/lib/ruby/bj/bj-1.0.1/README
require 'bj'

# see: http://github.com/mislav/will_paginate/wikis/installation
require 'will_paginate'

# If you are not using a common prefix for all table names in the database
# like: "sds_" then you will need to comment out the next two statements.

CGI::Session::ActiveRecordStore::Session.table_name = 'sds_sessions'

module ActiveRecord
  class Migrator
    def Migrator.schema_info_table_name
      Base.table_name_prefix + "sds_schema_info" + Base.table_name_suffix
    end
  end
end

# Time Zone things for consistent timestamps in the db
ActiveRecord::Base.default_timezone = :utc

require 'sds_init'
require 'uuidtools'
require 'b64'

# If you are using the SDS with TELS SAIL-WISE curnits you will
# need to point your SDS to an appropriate curnitmap and pdf server. 
# If this SDS is running locally, you'll need to install this as well.
# http://www.telscenter.org/confluence/display/SAIL/Setting+up+the+Curnitmap+and+PDF+server
# svn co https://tels.svn.sourceforge.net/svnroot/tels/trunk/workgroup-pdf-wrapper
# 
# PDF_SITE_ROOT="http://localhost:3003"

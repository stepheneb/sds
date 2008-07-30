# maybe use these recipes because we are using mongrel_cluster on the server
# where are they documented?
require 'mongrel_cluster/recipes'

set :application, "saildataservice"
set :repository,  "https://svn.concord.org/svn/sds/trunk"

set :mongrel_user, "mongrel"
set :mongrel_group, "users"

# Caches the svn co in shared and just does a svn up before copying the code to a new release
# see: http://blog.innerewut.de/tags/capistrano%20deployment%20webistrano%20svn%20subversion%20cache
set :deploy_via, :remote_cache

# set :ssh_options, { :forward_agent => true }

# If you aren't using Subversion to manage your source code, specify
# your SCM below:
# set :scm, :subversion

# set :user, "httpd"
# if SSH user defined in ~/.ssh/config use that name as the user
# otherwise use the user defined in ENV
set :user, File.open("#{ENV['HOME']}/.ssh/config", 'r') {|f| f.read}[/User (.*)/, 1] || ENV['USER']

role :app, "seymour.concord.org"
role :web, "seymour.concord.org"
role :db,  "seymour.concord.org", :primary => true

task :after_symlink, :roles => :app do
  run "cp #{shared_path}/config/database.yml #{release_path}/config/database.yml"
  run "cp #{shared_path}/config/environment.rb #{release_path}/config/environment.rb"
  run "ln -s #{shared_path}/cache #{release_path}/public/cache"
  run "cp #{shared_path}/config/mailer.yml #{release_path}/config/mailer.yml"
  run "cp #{shared_path}/config/exception_notifier_recipients.yml #{release_path}/config/exception_notifier_recipients.yml"
end

task :production do
  set :version, "production"
  set_vars
end

task :staging do
  set :version, "staging"
  set_vars
end

task :set_vars do
  # If you aren't deploying to /u/apps/#{application} on the target
   # servers (which is the default), you can specify the actual location
  # via the :deploy_to variable:
  set :deploy_to, "/web/#{version}/#{application}"
  
  set :mongrel_conf, "/etc/mongrel_cluster/#{version}-#{application}.yml"
  
  depend :remote, :file, "#{shared_path}/config/database.yml"
  depend :remote, :file, "#{shared_path}/config/environment.rb"
  depend :remote, :directory, "#{shared_path}/cache"
  depend :remote, :file, "#{shared_path}/config/mailer.yml"
  depend :remote, :file, "#{shared_path}/config/exception_notifier_recipients.yml"
end
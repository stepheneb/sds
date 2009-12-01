# maybe use these recipes because we are using mongrel_cluster on the server
# where are they documented?
require 'mongrel_cluster/recipes'

set :stages, %w(staging production)
require 'capistrano/ext/multistage'

set :application, "saildataservice"
set :repository,  "https://svn.concord.org/svn/sds/trunk"

set :erb_templates_folder, "lib/capistrano/recipes/templates"

set :mongrel_user, "mongrel"
set :mongrel_group, "users"

set(:subroot_pass) do
  Capistrano::CLI.password_prompt( "Enter the subroot mysql password: ")
end

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
  run "cp -r #{shared_path}/config/* #{release_path}/config"
  run "ln -s #{shared_path}/cache #{release_path}/public/cache"
end

depend :remote, :file, "#{shared_path}/config/database.yml"
depend :remote, :file, "#{shared_path}/config/environment.rb"
depend :remote, :directory, "#{shared_path}/cache"
depend :remote, :file, "#{shared_path}/config/mailer.yml"
depend :remote, :file, "#{shared_path}/config/exception_notifier_recipients.yml"
depend :remote, :file, "#{shared_path}/config/initializers/site_keys.rb"

task :disable_web, :roles => :web do
  on_rollback { delete "#{current_path}/public/system/maintenance.html" }

  output = render("maintenance.rhtml")
  put output, "#{current_path}/public/system/maintenance.html"
end

task :enable_web, :roles => :web do
  delete "#{current_path}/public/system/maintenance.html"
end

def render(template_file)
  require 'erb'
  template = File.read(erb_templates_folder + "/" + template_file)
  result = ERB.new(template).result(binding)  
end
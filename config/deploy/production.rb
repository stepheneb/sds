set :version, "production"

# If you aren't deploying to /u/apps/#{application} on the target
 # servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/web/production/#{application}"
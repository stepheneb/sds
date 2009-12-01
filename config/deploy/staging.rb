set :version, "staging"

# If you aren't deploying to /u/apps/#{application} on the target
 # servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/web/staging/#{application}"

task :reset_staging_db, :roles => :db do
  if version == "staging"
    # put the app into maintenance mode
    disable_web
    # dump the production db into the staging db
    run "mysqladmin -u subroot -p#{subroot_pass} -f drop staging_#{application}_prod"
    run "mysqladmin -u subroot -p#{subroot_pass} create staging_#{application}_prod"
    run "mysqldump -u subroot -p#{subroot_pass} --lock-tables=false --add-drop-table --quick --extended-insert production_#{application}_prod | mysql -u #{application} -p#{application} staging_#{application}_prod"
    # put app into running mode
    enable_web
    puts "You might want to run cap reset_staging_db on any DIYs that are configured to point to the staging SDS so that the database ids will match up correctly."
  else
    puts "You have to run in staging to execute this task."
  end
end

namespace :deploy do
  #############################################################
  #  Passenger
  #############################################################
      
  # Restart passenger on deploy
  desc "Restarting passenger with restart.txt"
  task :restart, :roles => :app, :except => { :no_release => true } do
    sudo "touch #{current_path}/tmp/restart.txt"
  end
  
  [:start, :stop].each do |t|
    desc "#{t} task is a no-op with passenger"
    task t, :roles => :app do ; end
  end
end
namespace :sds do
#  require 'lib/sds_init.rb'

  desc "display the cache path"
  task :path => :environment do
    puts SdsCache.instance.path
  end

  desc "Copy bundle.content to new model BundleContent.content (added in migration 45)."
  task :copy_bundle_content_to_related_model => :environment do
    puts "\nCopying bundle.content to related model ..."
    tracker = TimeTracker.new
    tracker.start
    puts "Bundles to process: #{Bundle.count.to_s}:"
    count = 1
    print "#{sprintf("%5d", count)}: "
    Bundle.find(:all, :select => 'id').each do |b1| 
      begin
        b2 = Bundle.find(b1.id)
        b2.bundle_content = BundleContent.new unless b2.bundle_content
        b2.bundle_content.content = b2.content
        b2.save!
        print 'p'
      rescue => e
        print 'x'
      end
      print "\n#{sprintf("%5d", count)}: " unless count.remainder(50) != 0
      count += 1
    end
    tracker.stop
  end
  
  desc "Download copies of curnit jars to local sds cache."
  task :copy_curnit_jars_to_sds_cache => :environment do
    puts "\nCopying curnit jars to sds_cache ..."
    tracker = TimeTracker.new
    tracker.start
    Curnit.find_all.each do |c| 
      cmdstring = "#{c.id}: #{c.name}: "
      c.jar_last_modified = nil
      begin 
        c.save!
        print "ok   :#{cmdstring}: "
      rescue
        print "error:#{cmdstring}: "
      end
      tracker.mark
      puts
    end
    tracker.stop
  end
  
  desc "Process Pods to set derived type information.."
  task :create_pod_derived_types => :environment do
    tracker = TimeTracker.new
    tracker.start
    puts "Pods to process: #{Pod.count.to_s}:"
    count = 1
    print "#{sprintf("%5d", count)}: "
    Pod.find(:all).each do |p|
      begin
        p.attributes=(p.kind)
        flag = 'p'
        if p.pas_type == 'note'
          p.html_body = p.get_html_body
          flag = 'n'
        end
        p.save!
        print flag
      rescue => e
        print 'x'
      end
      print "\n#{sprintf("%5d", count)}: " unless count.remainder(50) != 0
      count += 1
    end
    tracker.stop
    puts
  end
  
  desc 'Resave all the jnlp resources -- this will cause html_bodies and other web resource attributes to be set'
  task :rebuild_jnlps => :environment do
    require 'open-uri'
    jnlps = Jnlp.find(:all)
    puts "\nProcessing #{jnlps.length} Jnlps in database, collecting web resources ..."
    count = 1
    print "#{sprintf("%5d", count)}: "
    jnlps.each do |j| 
      begin
        if j.save
          print 'p'
          count += 1
        else
          print 'e'
          print "\n#{sprintf("%5d", count)}: " unless count.remainder(10) != 0
          count += 1
        end
      rescue => e
        print 'x'
        print "\n#{sprintf("%5d", count)}: " unless count.remainder(10) != 0
        count += 1
      end
    end
    valid_jnlps = Jnlp.find(:all).select {|j| j.body }
    invalid_jnlps = Jnlp.find(:all).select {|j| !j.body }
    puts "\nThere are #{valid_jnlps.length} valid jnlps (the web resource can be loaded) out of a total of #{jnlps.length} jnlps."
    puts "Valid jnlps: "
    valid_jnlps.each {|j| puts "id: #{j.id}, name: #{j.name}\n             url: #{j.url}"}
    puts "\nInvalid jnlps (not working): "
    invalid_jnlps.each {|j| puts "id: #{j.id}, name: #{j.name}\n             url: #{j.url}"}
  end
 
  desc "Clear sds_cache of Bundles, Pods; and Socks, delete Pods and Socks from db; regenerate db and sds_cache"
  task :rebuild_pods_and_socks => :environment do
    puts "\nRebuilding Pods and Socks ..."
    Bundle.rebuild_pods_and_socks(true)
  end
  
  desc "Process the Bundle content to update the sail_session attributes added in migration 42."
  task :create_sail_session_attributes => :environment do
    puts "\nCreating sail_session attributes ..."
    puts "Processing Bundles in database, recreating sail_session attributes ..."
    puts "Bundles to process: #{Bundle.count.to_s}:"
    count = 1
    print "#{sprintf("%5d", count)}: "
    tracker = TimeTracker.new
    tracker.start
    Bundle.find(:all, :order => "created_at ASC").each do |b|
      begin
        b.parse_content_xml
        b.process_sail_session_attributes
        print 'p'
      rescue => e
        print 'x'
      end
      print "\n#{sprintf("%5d", count)}: " unless count.remainder(50) != 0
      count += 1
    end
    tracker.stop
  end
  
  desc "Delete current database, copy from stable, convert tables ..."
  task :delete_copy_and_convert_db => :environment do
    # pull in config
    # stable db: name, host, user, pass
    # current db: is already known, but we still need it all defined)
    require 'config/db_transfer_config.rb'
    
    # get a connection to the current db
    con = User.connection
   
    # get the stable db
    print "Getting the stable database..."
    tables = `mysqlshow -u #{STABLE_DB_USER} --password='#{STABLE_DB_PASSWORD}' -h #{STABLE_DB_HOST} #{STABLE_DB_NAME} 'sds_%'`.scan(/sds_\S+/)[1..-1].join(' ')
    `mysqldump -u #{STABLE_DB_USER} --password='#{STABLE_DB_PASSWORD}' -h #{STABLE_DB_HOST} #{STABLE_DB_NAME} #{tables} > #{TEMP_FILE}`
    print " done.\n"
    
    # clear out the current db
    print "Deleting tables in the current database..."
    con.tables.each do |t|
      if t.match "^sds_"
        con.drop_table(t)
        print "."
      end
    end
    print " done.\n"
    
    # import the stable db
    print "Importing the stable database..."
    `mysql -u #{CURRENT_DB_USER} --password='#{CURRENT_DB_PASSWORD}' -h #{CURRENT_DB_HOST} #{CURRENT_DB_NAME} < #{TEMP_FILE}`
    print " done.\n"
    
    # do the db transformations
    print "Renaming tables and columns..."
    con.rename_table :sds_users, :sds_sail_users
    print "."
    con.rename_table :sds_sds_users, :sds_users
    print "."
    con.rename_table :sds_roles_sds_users, :sds_roles_users
    print "."
    con.rename_table :sds_offerings_users, :sds_offerings_sail_users
    print "."
    con.rename_column :sds_offerings_sail_users, :user_id, :sail_user_id
    print "."
    con.rename_column :sds_workgroup_memberships, :user_id, :sail_user_id
    print "."
    con.rename_column :sds_roles_users, :sds_user_id, :user_id
    print "."
    # have to set the db version to 42, since 43 in stable and 43 in trunk are not the same...
    con.execute("update sds_schema_info set version='42'")
    print ". done.\n"
    puts "Now apply migrations: 'rake db:migrate'/n"
  end

  desc "Rebuild database newly converted from stable. First apply migrations!"
  task :rebuild_db => [:environment, :create_sail_session_attributes, :copy_bundle_content_to_related_model, :copy_curnit_jars_to_sds_cache, :rebuild_pods_and_socks] do
  end
end
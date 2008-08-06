namespace :sds do
#  require 'lib/sds_init.rb'

  desc "display the cache path"
  task :path => :environment do
    puts SdsCache.instance.path
  end

  desc "Process any unprocessed bundles"
  task :process_unprocessed_bundles => :environment do
    puts "Processing any unprocessed bundles..."
    Bundle.find(:all, :conditions => "process_status = 3").each do |b|
      begin
        b.process_bundle_contents
        print '.'
      rescue => e
        print 'x'
        puts e
      end
    end
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
  
    desc "Copy bundle.content to new model BundleContent.content (added in migration 45)."
  task :fix_incorrect_airbag_data => :environment do
    puts "\nFixing incorrect Airbag model activity data ..."
    tracker = TimeTracker.new
    tracker.start
    puts "Datasets to process: #{ModelActivityDataset.count.to_s}:"
    count = 1
    print "#{sprintf("%5d", count)}: "
    ModelActivityDataset.find(:all).each do |mad| 
      begin
        if mad.name == "Airbag"
          mad.fix_incorrect_airbag_mad
          print 'p'
        else
          print '.'
        end
      rescue => e
        STDERR.puts "#{e}"
        if "#{e}".include? "MAD Dataset"
        else
          STDERR.puts "#{e.backtrace.join("\n")}"
        end
        print 'X'
      end
      print "\n#{sprintf("%5d", count)}: " unless count.remainder(50) != 0
      count += 1
    end
    tracker.stop
  end
  
  desc "Download copies of curnit jars to local sds cache."
  task :copy_curnit_jars_to_cache => :environment do
    puts "\nCopying curnit jars to cache ..."
    tracker = TimeTracker.new
    tracker.start
    Curnit.find(:all).each do |c| 
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
    puts "\nDon't forget to run 'sudo chmod -R lighttpd.lighttpd public/cache' to reset all the cache permissions so that it is usable by lighttpd!"
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
  
  desc "Create all the Model Activity Data from the pods and socks"
  task :rebuild_mad => :environment do
    tracker = TimeTracker.new
    tracker.start
    failures = []
    # delete any existing model_activity_datasets and their associated data
    ModelActivityDataset.find(:all) do |mad|
      mad.destroy
    end
    pods = Pod.find(:all, :conditions => "rim_name='model.activity.data' OR pas_type='ot_learner_data'")
    puts "Pods to process: #{pods.size}"
    count = 1
    print "#{sprintf("%5d", count)}: "
    i = j = 0
    pods.each do |p|
      p.socks.each do |s|
        i += 1
        begin
          s.save!
        rescue => e
          # puts "#{e}\n"
          j += 1
          $stderr.puts s.id
          failures.push(s.id)
        end
      end
      print (j > 0 ? (j > 10 ? "+" : "#{j}") : "p")
      if count.remainder(10) == 0
        print '  '
        tracker.mark
        ave = tracker.elapsed / count
        projected = (pods.size - count) * ave
        print " :: ave: #{TimeTracker.seconds_to_s(ave)}, projected: #{TimeTracker.seconds_to_s(projected)}"
        print "\n#{sprintf("%5d", count)}: "
      end
      count += 1
    end
    puts "Processed #{i} socks, #{j} failed."
    puts failures
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
 
  desc "Clear cache of Bundles, Pods; and Socks, delete Pods and Socks from db; regenerate db and cache"
  task :rebuild_pods_and_socks => :environment do
    puts "\nRebuilding Pods and Socks ..."
    Bundle.rebuild_pods_and_socks(true)
    puts "\nDon't forget to run 'sudo chmod -R lighttpd.lighttpd public/cache' to reset all the cache permissions so that it is usable by lighttpd!"
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
        if b.sail_session_modified_time == nil
          b.sail_session_modified_time = b.calc_modified_time
        end
        b.save!
        print 'p'
      rescue => e
        print 'x'
      end
      print "\n#{sprintf("%5d", count)}: " unless count.remainder(50) != 0
      count += 1
    end
    tracker.stop
  end
  

  desc "Rebuild database newly converted from stable. First apply migrations!"
  task :rebuild_db => [:environment, :copy_bundle_content_to_related_model, :create_sail_session_attributes, :copy_curnit_jars_to_cache, :rebuild_pods_and_socks] do
    puts "Don't forget to update any portals that are directly using the development SDS if the resources they refer to may have been deleted or had their primary keys changed.\nFor example the development TEEMSS2 DIY will need the following operations performed:\n  1. rake diy:delete_local_sds_attributes\n  2. manually update config/sds.yml to refer to the correct jnlp and curnit resources\n"
    puts "\nDon't forget to run 'sudo chmod -R lighttpd.lighttpd public/cache' to reset all the cache permissions so that it is usable by lighttpd!"
  end
  
  require 'activerecord'
  class RemoveSdsFromTableNames < ActiveRecord::Migration
    def self.up
      rename_table("sds_bundle_contents", "bundle_contents")
      rename_table("sds_bundles", "bundles")
      rename_table("sds_config_versions", "config_versions")
      rename_table("sds_curnit_maps", "curnit_maps")
      rename_table("sds_curnits", "curnits")
      rename_table("sds_errorbundles", "errorbundles")
      rename_table("sds_jnlps", "jnlps")
      rename_table("sds_log_bundles", "log_bundles")
      rename_table("sds_offerings", "offerings")
      rename_table("sds_offerings_attributes", "offerings_attributes")
      rename_table("sds_pas_computational_input_values", "pas_computational_input_values")
      rename_table("sds_pas_computational_inputs", "pas_computational_inputs")
      rename_table("sds_pas_findings", "pas_findings")
      rename_table("sds_pas_model_activity_datasets", "pas_model_activity_datasets")
      rename_table("sds_pas_model_activity_modelruns", "pas_model_activity_modelruns")
      rename_table("sds_pas_representational_attributes", "pas_representational_attributes")
      rename_table("sds_pas_representational_types", "pas_representational_types")
      rename_table("sds_pas_representational_values", "pas_representational_values")
      rename_table("sds_pods", "pods")
      rename_table("sds_portal_urls", "portal_urls")
      rename_table("sds_portals", "portals")
      rename_table("sds_rims", "rims")
      rename_table("sds_roles", "roles")
      rename_table("sds_roles_users", "roles_users")
      rename_table("sds_sail_users", "sail_users")
      rename_table("sds_schema_info", "schema_info")
      rename_table("sds_sessions", "sessions")
      rename_table("sds_socks", "socks")
      rename_table("sds_users", "users")
      rename_table("sds_workgroup_memberships", "workgroup_memberships")
      rename_table("sds_workgroups", "workgroups")
    end

    def self.down
      rename_table("bundle_contents", "sds_bundle_contents")
      rename_table("bundles", "sds_bundles")
      rename_table("config_versions", "sds_config_versions")
      rename_table("curnit_maps", "sds_curnit_maps")
      rename_table("curnits", "sds_curnits")
      rename_table("errorbundles", "sds_errorbundles")
      rename_table("jnlps", "sds_jnlps")
      rename_table("log_bundles", "sds_log_bundles")
      rename_table("offerings", "sds_offerings")
      rename_table("offerings_attributes", "sds_offerings_attributes")
      rename_table("pas_computational_input_values", "sds_pas_computational_input_values")
      rename_table("pas_computational_inputs", "sds_pas_computational_inputs")
      rename_table("pas_findings", "sds_pas_findings")
      rename_table("pas_model_activity_datasets", "sds_pas_model_activity_datasets")
      rename_table("pas_model_activity_modelruns", "sds_pas_model_activity_modelruns")
      rename_table("pas_representational_attributes", "sds_pas_representational_attributes")
      rename_table("pas_representational_types", "sds_pas_representational_types")
      rename_table("pas_representational_values", "sds_pas_representational_values")
      rename_table("pods", "sds_pods")
      rename_table("portal_urls", "sds_portal_urls")
      rename_table("portals", "sds_portals")
      rename_table("rims", "sds_rims")
      rename_table("roles", "sds_roles")
      rename_table("roles_users", "sds_roles_users")
      rename_table("sail_users", "sds_sail_users")
      rename_table("schema_info", "sds_schema_info")
      rename_table("sessions", "sds_sessions")
      rename_table("socks", "sds_socks")
      rename_table("users", "sds_users")
      rename_table("workgroup_memberships", "sds_workgroup_memberships")
      rename_table("workgroups", "sds_workgroups")
    end
  end
  
  desc "remove the prefix 'sds_' from all table names"
  task :remove_sds_from_table_names => :environment do
    RemoveSdsFromTableNames.up
  end
end

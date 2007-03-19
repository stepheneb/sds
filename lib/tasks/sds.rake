namespace :sds do
#  require 'lib/sds_init.rb'

  desc "display the cache path"
  task :path => :environment do
    puts SdsCache.instance.path
  end

  desc "Copy bundle.content to new model BundleContent.content (added in migration 45)."
  task :copy_bundle_content_to_related_model => :environment do
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
    tracker = TimeTracker.new
    tracker.start
    Curnit.find_all.each do |c| 
      c.jar_last_modified = nil
      print "#{c.id}: #{c.name}: "
      begin 
        c.save!
        print ' ok: '
      rescue
        print " error: " 
      end
      tracker.mark
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
    jnlps = Jnlp.find(:all)
    puts "\nProcessing #{jnlps.length} Jnlps in database, collecting web resources ..."
    count = 1
    print "#{sprintf("%5d", count)}: "
    Jnlp.find(:all).each do |j| 
        if j.get_body 
          j.save
          print 'p'
          count += 1
        else
          print 'e'
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
    Bundle.rebuild_pods_and_socks(true)
  end
  
  desc "Process the Bundle content to update the sail_session attributes added in migration 42."
  task :create_sail_session_attributes => :environment do
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
end

namespace :sds do

  desc "display the cache path"
  task :path => :environment do
    puts SdsCache.instance.path
  end

  desc "Copy bundle.content to new model BundleContent.content (added in migration 45)."
  task :copy_bundle_content_to_related_model => :environment do
    tracker = TimeTracker.new
    tracker.start
    Bundle.find(:all, :select => 'id').each do |b1| 
      b2 = Bundle.find(b1.id)
      b2.bundle_content = BundleContent.new
      b2.bundle_content.content = b2.content; b2.save
    end
    tracker.stop
  end
  
  desc "Download copies of curnit jars to local sds cache."
  task :copy_curnit_jars_to_sds_cache => :environment do
    tracker = TimeTracker.new
    tracker.start
    Curnit.find_all.each do |c| 
      c.jar_last_modified = nil
      print "#{c.id}: #{c.name}"
      begin 
        c.save!
      rescue
        print " error " 
      ensure 
        puts 
      end
    end
    tracker.stop
  end
 
  desc "Clear sds_cache of Bundles, Pods; and Socks, delete Pods and Socks from db; regenerate db and sds_cache"
  task :rebuild_pods_and_socks => :environment do
    Bundle.rebuild_pods_and_socks
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
namespace :sds do
#  require 'lib/sds_init.rb'

  namespace :setup do
    
    desc "Raise an error unless the RAILS_ENV is development"
    task :development_environment_only do
      raise "Hey, development only you monkey!" unless RAILS_ENV == 'development'
    end

    desc "setup a new sds instance"
    task :new_sds_from_scratch => :environment do
      begin
        Rake::Task['db:drop'].invoke
      rescue Exception
      end
      Rake::Task['sds:setup:development_environment_only'].invoke
      Rake::Task['db:create'].invoke
      Rake::Task['db:migrate'].invoke
      Rake::Task['sds:setup:default_users_roles'].invoke
      Rake::Task['sds:setup:config:setup_all_config_versions'].invoke
      
      puts <<HEREDOC

You can now start the SDS by running this command:

  script/server

You can re-edit the configuration parameters by running:

  ruby config/setup.rb

You can also create an OTrunk Examples Portal Realm in the SDS with this rake task:

  rake sds:setup:otrunk_testing_portal
  
HEREDOC

    end
    
    def edit_user(user)
      require 'highline/import'
      
      puts <<HEREDOC

Editing user: #{user.login}

HEREDOC

      user.login =                 ask("            login: ") {|q| q.default = user.login}
      user.email =                 ask("            email: ") {|q| q.default = user.email}
      user.first_name =            ask("       first name: ") {|q| q.default = user.first_name}
      user.last_name =             ask("        last name: ") {|q| q.default = user.last_name}
      user.password =              ask("         password: ") {|q| q.default = user.password}
      user.password_confirmation = ask(" confirm password: ") {|q| q.default = user.password_confirmation}
      
      user
    end
      
      
    
    desc "Create default users and roles"
    task :default_users_roles => :environment do

      puts <<HEREDOC

This task creates four roles (if they do not already exist):

  admin
  researcher
  member
  guest

In addition it create three new default users with these logins:

  admin
  researcher
  member

You can edit the default settings for these users.

HEREDOC

      admin_role = Role.find_or_create_by_title('admin')
      researcher_role = Role.find_or_create_by_title('researcher')
      member_role = Role.find_or_create_by_title('member')
      guest_role = Role.find_or_create_by_title('guest')

      admin_user = User.create(:login => "admin", :email => "admin@concord.org", :password => "password", :password_confirmation => "password", :first_name => "Admin", :last_name => "User")
      researcher_user = User.create(:login => 'researcher', :first_name => 'Researcher', :last_name => 'User', :email => 'researcher@concord.org', :password => "password", :password_confirmation => "password")
      member_user = User.create(:login => 'member', :first_name => 'Member', :last_name => 'User', :email => 'member@concord.org', :password => "password", :password_confirmation => "password")

      edit_user(admin_user).save
      edit_user(researcher_user).save
      edit_user(member_user).save

      admin_user.roles << admin_role 
      researcher_user.roles << researcher_role

      puts

    end

    desc "Creates (or finishes creating) an sds portal-realm to run a local copy of otrunk-examples"
    task :otrunk_testing_portal => :environment do
    
      # Ruby command line interface toolkit, see: http://highline.rubyforge.org/
      require 'highline' 
    
      hl = HighLine.new

      puts <<HEREDOC

This task will create (or finish creating) an sds portal-realm to run a local 
copy of otrunk-examples

You will need to first set the urls for the SDS and for the all-otrunk jnlp:

HEREDOC
    
      sds_host = hl.ask("Url for SDS host?\n\n  ") { |q| q.default = "http://localhost:3000" }

      puts

      jnlp_url = hl.ask("Url for all-otrunk-snapshot.jnlp?\n\n  ") { |q| 
        q.default = "http://jnlp/org/concord/maven-jnlp/all-otrunk-snapshot/all-otrunk-snapshot.jnlp" 
      }

   
      return unless hl.agree("Do you want to continue? (y/n): ", true)

      # Temporarily add a new find_or_create_by_attributes method to ActiveRecord::Base
      # This makes the code below a little bit simpler to read -- and, if there is a problem
      # running this script (like forgetting to make sure the Tomcat jnlp server is running)
      # you can fix the problem and re-run the script without worrying about making a 
      # duplicate portal realm.
      module ActiveRecord #:nodoc:
        class Base
          class << self # Class method
            def find_or_create_by_attributes(attributes)
              self.find(:first, :conditions => attributes) || self.create(attributes)
            end
          end
        end
      end

      portal_attributes = { 
        :name => "OTrunk Examples", 
        :use_authentication => false, 
        :title => "OTrunk Examples", 
        :vendor => "Concord Consortium", 
        :home_page_url => "https://confluence.concord.org/display/CSP/OTrunk", 
        :description => "A test.", 
        :image_url => "/images/sail_orangecirc_64.gif", 
        :last_bundle_only =>  true 
      }

      portal = Portal.find_or_create_by_attributes(portal_attributes)

      curnit_attributes = { 
        :name => "diy curnit stub", 
        :always_update => false, 
        :url => "#{sds_host}/curnits/otrunk-curnit-external-diytest.jar"
      }

      curnit = portal.curnits.find_or_create_by_attributes(curnit_attributes)

      jnlp_attributes = { 
        :name => "all otrunk Snapshot", 
        :always_update => true, 
        :url => "http://jnlp/org/concord/maven-jnlp/all-otrunk-snapshot/all-otrunk-snapshot.jnlp" 
      }

      jnlp = portal.jnlps.find_or_create_by_attributes(jnlp_attributes)

      sail_user_attributes = {
        :first_name => "OTrunk", 
        :last_name => "Examples"
      }

      sail_user = portal.sail_users.find_or_create_by_attributes(sail_user_attributes)

      offering_attributes = {
        :name => "OTrunk Examples", 
        :curnit_id => curnit.id, 
        :jnlp_id => jnlp.id
      }

      offering = portal.offerings.find_or_create_by_attributes(offering_attributes)

      # FIXME
      # the portal_id should not be part of this model because it is included in
      # the offering and the workgroup is dependent on the offering
      workgroup_attributes = {
        :portal_id => portal.id,
        :name => "OTrunk Examples"
      }

      workgroup = offering.workgroups.find_or_create_by_attributes(workgroup_attributes)

      workgroup_membership_attributes = {
        :sail_user_id => sail_user.id, 
        :version => workgroup.version
      }

      wm = workgroup.workgroup_memberships.find_or_create_by_attributes(workgroup_membership_attributes)

      # generate the correct url to use to run the otrunk-examples offering
      rs = ActionController::Routing::Routes
      view_path = rs.generate(:pid => portal.id, :controller => "offering", :action => "jnlp", :id => offering.id, 
      :wid => workgroup.id, :type => "workgroup", :savedata => nil, :only_path => false)

      puts <<HEREDOC

SDS portal realm: #{portal.name} (#{portal.id}) created.

The SAIL Jnlp view path to the new offering is:

  #{sds_host}#{view_path}

HEREDOC

    end
    
    
    namespace :config do

      configHeader = 'xml.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
         xml.java("version" => "1.4.0", "class" => "java.beans.XMLDecoder") {'.gsub(/^       /, '')

      configFooter = "\n}"

      configCurnitProvider = '
         xml.object("class" => "net.sf.sail.core.service.impl.CurnitUrlProviderImpl") {
           xml.void("property" => "url") {
             xml.string(@curnit_url)
           }
         }'

      configPortfolioManagerService = '
         xml.object("class" => "net.sf.sail.emf.launch.PortfolioManagerService") {
           xml.void("property" => "portfolioUrlProvider") {
             xml.object("class" => "net.sf.sail.emf.launch.XmlUrlStringProviderImpl") {
               xml.void("property" => "urlString") {
                 xml.string(@bundle_get_url)
               }
             }
           }
           if @savedata
           xml.void("property" => "bundlePoster") {
             xml.object("class" => "net.sf.sail.emf.launch.BundlePoster") {
               xml.void("property" => "postUrl") {
                 xml.string(@bundle_post_url)
               }
             }
           }
           end
         }'

      configLauncherService = '
         xml.object("class" => "net.sf.sail.core.service.impl.LauncherServiceImpl") {
           xml.void("property" => "properties") {
             xml.object("class" => "java.util.Properties") {
               xml.void("method" => "setProperty") {
                 xml.string("sds_time")
                 xml.string((Time.now.to_f * 1000).to_i)
               }
               @offering_attributes.each do |k,v| 
                 xml.void("method" => "setProperty") {
                   xml.string(k)
                   xml.string(v)
                 }
               end
             }
           }
         }'

      configSDSDataStore = '
         xml.object("class" => "net.sf.sail.emf.launch.EMFSailDataStoreService2")'

      configJackrabbitRMI = '
         xml.object("class" => "org.concord.otrunk.jackrabbit.JackrabbitSPIRMIUserSessionProvider"){
           xml.void("property" => "repositoryUrl"){
             xml.string("http://localhost:8080/jackrabbit-1.5/rmi")
           }
           xml.void("property" => "workspaceName"){
             xml.string("default")
           }
         }'

      configUserService = '
         xml.object("class" => "net.sf.sail.core.service.impl.UserServiceImpl") {
           xml.void("property" => "participants") {
             @sail_users = @workgroup.sail_users.version(@version)
             @sail_users.each do |u|
               add_user_to_config(xml, u)
             end          
           }
           xml.void("property" => "userLookupService") {
             xml.object("class" => "net.sf.sail.core.service.impl.UserLookupServiceImpl")
           }
         }'

      configUserServiceWithWorkgroupId = '
         xml.object("class" => "net.sf.sail.core.service.impl.UserServiceImpl") {
           xml.void("property" => "workgroupUuid") {
             xml.object("class" => "net.sf.sail.core.uuid.AgentUuid"){
               xml.string(@workgroup.uuid)
             }
           }
           xml.void("property" => "participants") {
             @sail_users = @workgroup.sail_users.version(@version)
             @sail_users.each do |u|
               add_user_to_config(xml, u)
             end          
           }
           xml.void("property" => "userLookupService") {
             xml.object("class" => "net.sf.sail.core.service.impl.UserLookupServiceImpl")
           }
         }'

      configStandardServices = '
         xml.object("class" => "net.sf.sail.core.service.impl.SessionLoadMonitor")  
         xml.object("class" => "net.sf.sail.core.service.impl.SessionManagerImpl")'


     configConsoleLoggingAlways = '
        xml.object("class" => "net.sf.sail.emf.launch.ConsoleLogServiceImpl") {
          xml.void("property" => "bundlePoster") {
            xml.object("class" => "net.sf.sail.emf.launch.BundlePoster") {
              xml.void("property" => "postUrl") {
                xml.string(@controller.url_for(
                                :controller => "log_bundles", 
                                :action => "index", 
                                :id => @offering.id, 
                                :wid => @workgroup.id,
                                :pid => @portal.id,
                                :only_path => false))
              }
            }
          }
        }'
            
      configConsoleLogging = '
         xml.object("class" => "net.sf.sail.emf.launch.ConsoleLogServiceImpl") {
           if @savedata
             xml.void("property" => "bundlePoster") {
               xml.object("class" => "net.sf.sail.emf.launch.BundlePoster") {
                 xml.void("property" => "postUrl") {
                   xml.string(@controller.url_for(
                                   :controller => "log_bundles", 
                                   :action => "index", 
                                   :id => @offering.id, 
                                   :wid => @workgroup.id,
                                   :pid => @portal.id,
                                   :only_path => false))
                 }
               }
             }
           end
         }'

      configOTrunkViewSystemCurnit = '
         xml.object("class" => "org.telscenter.sailotrunk.OtmlUrlCurnitProvider") {
           xml.void("property" => "viewSystem") {
             xml.boolean("true")
           }
         }'

      configOTrunkControllerSystemCurnit = '
        xml.object("class" => "org.telscenter.sailotrunk.OtmlUrlCurnitProvider")'

      desc "Set all Jnlps to use the original default ConfigVersion template."
      task :setup_all_jnlps_to_use_original_config_version => [:environment, :setup_default_config_versions] do
        puts "\nContinuing this task will set all existing jnlps to use the original SDS style.\n"
        print "Would you like to proceed? [y/N]: "
        response = STDIN.gets
        response = response.chomp 
        puts ""
        case response
        when "y", "Y", "yes", "Yes"
          # continue
        when "n", "N", "no", "No", ""
          puts "Aborting."
          return
        else
          puts "Invalid response. Aborting."
          return
        end
        orig = ConfigVersion.find_by_key('config1')
        Jnlp.find(:all).each do |j|
          begin
            j.config_version = orig
            j.save!
            print "."
          rescue => e
            puts "\nFailed to save jnlp #{j.id}: #{e}\n"
          end
        end
        puts
      end

      def legacy_find_or_create(key, original_name)
        unless cv = ConfigVersion.find_by_key(key)
          if cv = ConfigVersion.find_by_name(original_name)
            # check if someone reused this name with a different key
            # if so create a new ConfigVersion with this key
            if cv.key && !cv.key.blank?
              cv = ConfigVersion.create(:key => key)
            else
              cv.key = key
            end
          else
            cv = ConfigVersion.create(:key => key)
          end
        end
        cv
      end

      desc "Set up the default ConfigVersions"
      task :setup_default_config_versions => :environment do
        orig = legacy_find_or_create('persist:sds content:curnit', "Original style")
        orig.attributes = {
          :name => "Original style",
          :description => "This configures the user data to be stored in the sds using sail-data-emf library.  
           It does not save and send the console log back.",
          :version => 1.0, 
          :template => 
            (configHeader + 
            configCurnitProvider +
            configPortfolioManagerService +
            configLauncherService +
            configSDSDataStore +
            configUserService + 
            configStandardServices +
            configFooter) }
        orig.save!
        puts "Created/updated: id: #{orig.id}, key: #{orig.key}, name: #{orig.name}"

        cv = legacy_find_or_create('persist:sds content:curnit logging', "With console logging");
        cv.attributes = { 
          :name => "With console logging",
          :description => "This configures the user data to be stored in the sds using sail-data-emf library.  
           It saves and sends the console log back.",
          :version => 1.1, 
          :template => 
            (configHeader + 
            configConsoleLogging +
            configCurnitProvider +
            configPortfolioManagerService +
            configLauncherService +
            configSDSDataStore +
            configUserService +
            configStandardServices +
            configFooter) }
        cv.save!
        puts "Created/updated: id: #{cv.id}, key: #{cv.key}, name: #{cv.name}"
      end

      desc "Setup OTrunk config versions"
      task :setup_otrunk_config_versions => :environment do
        cv = ConfigVersion.find_or_initialize_by_key(:key => 'persist:sds content:otml-view logging')
        cv.attributes = {
        :name => "OTrunk View System With console logging",
        :description => "This configures the user data to be stored in the sds using the sail-data-emf library.
          It loads content from an otml file and uses the OTViewer to display it.
          It saves and sends the console log back only if learner data will be saved.",
        :version => 1.1, 
        :template => 
          (configHeader + 
          configConsoleLogging +
          configOTrunkViewSystemCurnit +
          configPortfolioManagerService +
          configLauncherService +
          configSDSDataStore +
          configUserService +
          configStandardServices +
          configFooter) }
        cv.save!
        puts "Created/updated: id: #{cv.id}, key: #{cv.key}, name: #{cv.name}"

        cv = ConfigVersion.find_or_initialize_by_key(:key => 'persist:sds content:otml-controller logging')
        cv.attributes = {
          :name => "OTrunk Contoller System With console logging",
          :description => "This configures the user data to be stored in the sds using the sail-data-emf library.
          It loads content from an otml file and uses the controller system to load the root object which is treated as the root bean in a sail curnit.
          It saves and sends the console log back only if learner data will be saved.",
          :version => 1.1, 
          :template =>
            (configHeader + 
            configConsoleLogging +
            configOTrunkControllerSystemCurnit +
            configPortfolioManagerService +
            configLauncherService +
            configSDSDataStore +
            configUserService +
            configStandardServices +
            configFooter) }
        cv.save!
        puts "Created/updated: id: #{cv.id}, key: #{cv.key}, name: #{cv.name}"
        
        cv = ConfigVersion.find_or_initialize_by_key(:key => 'persist:sds content:otml-view logging-always')
        cv.attributes = {
        :name => "OTrunk View System With console logging always enabled",
        :description => "This configures the user data to be stored in the sds using the sail-data-emf library.
          It loads content from an otml file and uses the OTViewer to display it.
          It saves and sends the console log back always.",
        :version => 1.1, 
        :template => 
          (configHeader + 
          configConsoleLoggingAlways +
          configOTrunkViewSystemCurnit +
          configPortfolioManagerService +
          configLauncherService +
          configSDSDataStore +
          configUserService +
          configStandardServices +
          configFooter) }
        cv.save!
        puts "Created/updated: id: #{cv.id}, key: #{cv.key}, name: #{cv.name}"
      end            

      desc "Setup Jackrabbit config versions"
      task :setup_jackrabbit_config_versions => :environment do
        cv = ConfigVersion.find_or_initialize_by_key(:key => 'persist:jackrabbit-spi-rmi content:otml-view logging')
        cv.attributes = {
          :name => "Jackrabbit OTrunk View System With console logging",
          :description => "This configures the user data to be stored in a jackrabbit repository.
          It loads content from an otml file and uses the OTViewer to display it.
          It saves and sends the console log back.",
          :version => 1.1,
          :template => 
            (configHeader + 
            configConsoleLogging +
            configOTrunkViewSystemCurnit +
            configLauncherService +
            configJackrabbitRMI +
            configUserServiceWithWorkgroupId +
            configStandardServices +
            configFooter) }
        cv.save!
        puts "Created/updated: id: #{cv.id}, key: #{cv.key}, name: #{cv.name}"
      end

      desc "Set up all the ConfigVersion instances"
      task :setup_all_config_versions => 
        [:environment, :setup_default_config_versions, :setup_otrunk_config_versions, :setup_jackrabbit_config_versions] do 
      end
    end
    
  end
  
  namespace :notification do
    types = []
    
    task :define_types do
      bundle_create_type = {:name => "Bundle Create", :key => "bundle:create", :description => "Fired whenever a bundle is created."}
      bundle_create_type[:script] = '
# @object is a Bundle
require "action_controller/integration"

# initialize app so that we can do route resolution
app = ActionController::Integration::Session.new
app.host = @object.sds_return_address.host
@portal = @object.workgroup.portal

hash = {}
hash[:workgroup_id] = @object.workgroup_id
hash[:offering_id] = @object.workgroup.offering_id
hash[:portal_id] = @object.workgroup.portal_id
hash[:bundle_id] = @object.id
hash[:bundle_url] = app.bundle_url(:pid => @portal, :id => @object)
hash[:bundle_content_url] = app.bundle_content_url(:pid => @portal, :id => @object.bundle_content)
hash[:bundle_ot_learner_data_url] = app.ot_learner_data_bundle_content_url(:pid => @portal, :id => @object.bundle_content)
hash[:event_type] = "create"

post_data(@url, hash)
'
      types << bundle_create_type
    end
  
    desc "create/update default notification types"
    task :setup_default_notification_types => [:environment, :define_types] do
      types.each do |t|
        created = false
        nt = NotificationType.find_by_key(t[:key]) || NotificationType.find_by_name(t[:name])
        if ! nt
          nt = NotificationType.new
          created = true
        end
        nt.key = t[:key]
        nt.name = t[:name]
        nt.description = t[:description]
        nt.script = t[:script]
        if ! nt.save
          puts "Failed to save #{created ? "new" : ""} NotificationType: #{nt.key} - #{nt.name}"
        else
          puts "#{created ? "Created" : "Updated"} NotificationType: #{nt.key} - #{nt.name}"
        end
      end
    end
  
  end

  namespace :utils do
    desc "populate the bundle launch property attributes added in migration 085"
    task :populate_the_bundle_launch_property_attributes => :environment do
      include ProcessLogger
      bundle_count = Bundle.count
      puts "\nProcessing BundleContent from #{bundle_count} Bundles to generate bundle launch property attributes added in migration 085."
     limit = 100
     offset = Bundle.find(:first, :order => 'id asc').id
     max_offset = Bundle.find(:first, :order => 'id desc').id
     size = max_offset - offset
     puts "max = #{max_offset}"
     while offset < max_offset
       print "\n#{0-((1000*(offset-max_offset))/size)/10.0}: "
       Bundle.find(:all, :conditions => "id >= #{offset} AND id < #{offset + limit}").each do |b|
         begin
           doc = XML::Parser.string(b.bundle_content.content).parse
           
           b.is_otml = doc.find('//sockParts[@rimName="ot.learner.data"]/sockEntries').empty?
           lp = {}
           doc.find('//launchProperties').each {|l| lp[l['key']] = l['value']}
                 
           b.maven_jnlp_version         = lp['maven.jnlp.version']
           b.sds_time                   = lp['sds_time']
           b.sailotrunk_otmlurl         = lp['sailotrunk.otmlurl']
           b.maven_jnlp_version         = lp['maven.jnlp.version']
           b.jnlp_properties            = lp['jnlp_properties']
           b.previous_bundle_session_id = lp['previous.bundle.session.id']
           b.save
           print '.'
         rescue => e
           print 'x'
           $stderr.puts "#{b.id}: #{e}"
         end
       end
       offset += limit
     end
     puts ""
     puts " done."
    end
    
    desc "display the cache path"
    task :path => :environment do
      puts SdsCache.instance.path
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
        ActiveRecord::Base.connection.tables.each do |table|
          new_table = table.sub(/^sds_/, "")
          if table != new_table
            puts "Renaming table '#{table}' to '#{new_table}'"
            rename_table(table, new_table)
          end
        end
      end

      def self.down
        skip_tables = ["bj_config", "bj_job", "bj_job_archive" ]
        ActiveRecord::Base.connection.tables.each do |table|
          next if skip_tables.include?(table)
          next if table =~ /^sds_/
          new_table = "sds_" + table
          puts "Renaming table '#{table}' to '#{new_table}'"
          rename_table(table, new_table)
        end
      end
    end

    desc "remove the prefix 'sds_' from all table names"
    task :remove_sds_from_table_names => :environment do
      RemoveSdsFromTableNames.up
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
    
    desc "Replace all OTBlob contents in a bundle with a url pointing to a blob object with those contents"
    task :remove_blob_content_from_bundles => :environment do
      host = nil
      if ! ENV['HOST']
        puts "If you want to set the blob urls to a particular host, set the HOST environment variable to the host address."
        puts "e.g. HOST=http://foo.bar.com/ rake sds:utils:remove_blob_content_from_bundles"
      else
        host = URI.parse(ENV['HOST']).host
      end
      
      puts "Pulling OTBlob contents..."
			limit = 100
			offset = Bundle.find(:first, :order => 'id asc').id
			max_offset = Bundle.find(:first, :order => 'id desc').id
			size = max_offset - offset
			puts "max = #{max_offset}"
			while offset < max_offset
			  print "\n#{0-((1000*(offset-max_offset))/size)/10.0}: "
				Bundle.find(:all, :conditions => "id >= #{offset} AND id < #{offset + limit}").each do |b|
          begin
            num = b.process_ot_blob_resources({:host => host, :reparse => true})
            print num > 9 ? "+" : (num == 0 ? "." : "#{num}")
          rescue => e
            print 'x'
            $stderr.puts "#{b.id}: #{e}"
          end
				end
				offset += limit
			end
			puts ""
			puts " done."
    end
    
    desc "Replace all OTBlob contents in a sock with a url pointing to a blob object with those contents"
    task :remove_blob_content_from_socks => :environment do
      host = nil
      if ! ENV['HOST']
        puts "If you want to set the blob urls to a particular host, set the HOST environment variable to the host address."
        puts "e.g. HOST=http://foo.bar.com/ rake sds:utils:remove_blob_content_from_socks"
      else
        host = URI.parse(ENV['HOST']).host
      end
      
      puts "Pulling OTBlob contents..."
      limit = 100
      offset = Sock.find(:first, :order => 'id asc').id
      max_offset = Sock.find(:first, :order => 'id desc').id
      size = max_offset - offset
      puts "max = #{max_offset}"
			i = 0
      while offset < max_offset
        print "\n#{0-((1000*(offset-max_offset))/size)/10.0}: " if (i % 50 == 0)
				num = 0
        Sock.find(:all, :conditions => "id >= #{offset} AND id < #{offset + limit}").each do |s|
          begin
            num += s.process_ot_blob_resources(host)
            # print num > 9 ? "+" : (num == 0 ? "." : "#{num}")
          rescue => e
            # print 'x'
            # $stderr.puts "#{s.id}: #{e}"
          end
        end
        print num > 9 ? "+" : (num == 0 ? "." : "#{num}")
        offset += limit
				i += 1
      end
      puts ""
      puts " done."
    end
    
    desc "Update all blob urls to point to a new host"
    task :update_blob_urls => :environment do
      if ! ENV['HOST']
        puts "You need to set the HOST environment variable to the host address to which you want to update the blob urls."
        puts "e.g. HOST=http://foo.bar.com/ rake sds:utils:update_blob_urls"
        return
      end
      host = URI.parse(ENV['HOST']).host
      
      puts "Updating bundles and socks..."
      limit = 100
      offset = Blob.find(:first, :order => 'id asc').id
      max_offset = Blob.find(:first, :order => 'id desc').id
      size = max_offset - offset
      puts "max = #{max_offset}"
      seen_bundles = []
      while offset < max_offset
        print "\n#{0-((1000*(offset-max_offset))/size)/10.0}: "
        Blob.find(:all, :conditions => "id >= #{offset} AND id < #{offset + limit}").each do |b|
          b.bundles.each do |b|
            next if seen_bundles.include?(b.id)
            begin
              b.process_ot_blob_resources({:host => host, :reparse => true})
            rescue
            end
            b.socks.each do |s|
              begin
                s.process_ot_blob_resources(host)
              rescue
              end
            end
            seen_bundles << b.id
          end
          print "."
        end
        offset += limit
      end
      puts ""
      puts " done."
    end
    
  end
  namespace :legacy do

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
    
    desc "Clear cache of Bundles, Pods; and Socks, delete Pods and Socks from db; regenerate db and cache"
    task :rebuild_pods_and_socks => :environment do
      puts "\nRebuilding Pods and Socks ..."
      Bundle.rebuild_pods_and_socks(true)
      puts "\nDon't forget to run 'sudo chmod -R lighttpd.lighttpd public/cache' to reset all the cache permissions so that it is usable by lighttpd!"
    end

  end

end

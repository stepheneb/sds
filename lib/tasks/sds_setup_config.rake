namespace :sds_config do

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

  desc "Set up the default ConfigVersions"
  task :setup_default_config_versions => :environment do
    orig = ConfigVersion.find_or_initialize_by_key(:key => 'config1')
    orig.attributes = {
      :name => "Original style",
      :description => "The original SDS config format.",
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

    cv = ConfigVersion.find_or_initialize_by_key(:key => 'config2')
    cv.attributes = { 
      :name => "With console logging",
      :description => "The original SDS config format plus logging the Java console back to the SDS.",
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
    cv = ConfigVersion.find_or_initialize_by_key(:key => 'config3')
    cv.attributes = {
    :name => "OTrunk View System With console logging",
    :description => "",
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

    cv = ConfigVersion.find_or_initialize_by_key(:key => 'config4')
    cv.attributes = {
      :name => "OTrunk Contoller System With console logging",
      :description => "",
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
  end            

  desc "Setup Jackrabbit config versions"
  task :setup_jackrabbit_config_versions => :environment do
    cv = ConfigVersion.find_or_initialize_by_key(:key => 'config5')
    cv.attributes = {
      :name => "Jackrabbit OTrunk View System With console logging",
      :description => "",
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

  desc "Set up the all ConfigVersions"
  task :setup_all_config_versions => 
    [:environment, :setup_default_config_versions, :setup_otrunk_config_versions, :setup_jackrabbit_config_versions] do end
end 

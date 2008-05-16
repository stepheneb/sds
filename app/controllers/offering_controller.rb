class OfferingController < ApplicationController

  require 'zlib'
  # require 'spreadsheet/excel'
  require 'csv'
  require 'open-uri'

  require 'spawn'
  include Spawn

  before_filter :log_referrer
  before_filter :find_offering, :except => [ :list, :create ]

  after_filter :compress, :only => [:bundle]
  
  after_filter :add_md5_checksum, :only => [:bundle]

  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 2**21-1 # 2M  

  protected

  def find_offering
    @offering = find_portal_resource('Offering', params[:id])
  end  

  public

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        xml_parms = ConvertXml.xml_to_hash(request.raw_post)
        @offering = Offering.new(xml_parms)
        @offering.curnit = Curnit.find(xml_parms['curnit_id'])
        @offering.jnlp = Jnlp.find(xml_parms['jnlp_id'])
        @offering.portal = @portal
        if @offering.save
          response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
          render(:xml => "", :status => 201) # Created
        else
          errors =  @offering.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
          render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
        end
      rescue => e
        render(:text => "Application error: #{e}", :status => 500)
      end
    else
      respond_to do |wants|
        wants.html{
          @offerings = Offering.search(params[:search], params[:page], @portal)
        }
        wants.xml {
          offerings = @portal.offerings
          render :xml => (offerings.empty? ? "<offerings />" : offerings.to_xml(:except => ['created_at', 'updated_at']))
        }
      end
    end
  end

  def edit
    if request.post?
      if @offering.update_attributes(params[:offering])
        flash[:notice] = "Offering #{@offering.id} was successfully updated."
        redirect_to :action => 'list'
      end
    else
      @offering = Offering.find(params[:id])
    end
  end

  def create
    if request.post?
      parms = params[:offering].merge({ "portal_id" => params[:pid]})
      @offering = Offering.new(parms)
      if @offering.save
        flash[:notice] = "Offering #{@offering.id} was successfully created."
        redirect_to :action => 'list'
      else
        flash[:notice] = "Error creating Offering." 
      end
    else
      @offering = Offering.new
    end
  end

  def show
    begin
      @offering = @portal.offerings.find(params[:id])
      if request.get?
        pdf_host = (request.env['HTTP_X_FORWARDED_SERVER'] ? request.env['HTTP_X_FORWARDED_SERVER'] : request.env['HTTP_HOST']) 
        pdf_relative_root = request.env['REQUEST_URI'].match(/(.*)\/[\d]+\/offering\/[\d]+[\/]?/)[1]
        @sdsBaseUrl = "http://#{pdf_host}#{pdf_relative_root}"
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @offering.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          if @offering.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
            response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
            render(:xml => "", :status => 201) # Created
          else
            errors =  @offering.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
            render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
          end
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.delete?
        @offering.destroy
        render(:text => '', :status => 204) # No Content
      end
      #    rescue => e
      #      render(:text => e, :status => 404) # Not Found
    end
  end

  def destroy
    #    id = params[:id]
    #    begin
    #      Offering.find(id).destroy
    #      flash[:notice] = "Offering #{id.to_s} was successfully deleted."
    #    rescue => e
    #      flash[:notice] = "Error deleting Offering #{id.to_s}." 
    #    end
    #    redirect_to :action => :list
  end

  def jnlp
    @jnlp = @offering.jnlp
    if @jnlp.always_update || @jnlp.body.blank?
      @jnlp.save!
    end
    if @jnlp.body.blank?
      external_resource_not_found('Jnlp', @jnlp.id, @jnlp.url)
    elsif !@jnlp.body_xml
      external_resource_not_well_formed_xml('Jnlp', @jnlp.id, @jnlp.url)
    else
      case params[:type]
      when 'user'
        @workgroup = SailUser.find(params[:uid]).workgroup
      when 'workgroup'
        @workgroup = Workgroup.find(params[:wid])
      end
      @savedata = params[:savedata]
      @nobundles = params[:nobundles]
      # need last mod?
      response.headers["Content-Type"] = "application/x-java-jnlp-file"
      response.headers["Cache-Control"] = "max-age=1"
      # look for any dynamically added jnlp parameters
      # jnlp_filename's value is used by the sds when it constructs the Content-Disposition header
      jnlp_filename = request.query_parameters['jnlp_filename'] || "#{to_filename(@jnlp.name)}_#{to_filename(@offering.curnit.name)}.jnlp"
      # this is a bit of a hack because the real query_parameters are not a hash
      # so I delete the jnlp_filename parameter if it exists in request.query_string
      request.query_string.gsub!(/[?&]jnlp_filename=[^&]*/, '')
      response.headers["Content-Disposition"] = "attachment; filename=#{jnlp_filename}"
      # jnlp_properties value is a string of key-value pairs in a url query-string format
      # in which the reserved characters 
      if request.query_parameters['jnlp_properties']
        @jnlp_properties = parse_query_parameters(URI.unescape(request.query_parameters['jnlp_properties']))
        request.query_string.gsub!(/[?&]jnlp_properties=[^&]*/, '')
        # if @jnlp_properties.has_key?('otrunk.view.author') && !@jnlp_properties.has_key?('otrunk.view.mode')
        #   @jnlp_properties.merge!({'otrunk.view.mode' => 'authoring'})
        # end
      end
      render :action => 'jnlp', :layout => false
    end
  end

  def atom
    #    @offering = Offering.find(params[:id])
    #    @workgroups = @offering.workgroups
    #    response.headers["Content-Type"] = "application/atom+xml"
  end

  def config
    begin
      @offering = Offering.find(params[:id])
      @workgroup = Workgroup.find(params[:wid])
      @version = params[:version]
      @savedata = params[:savedata]
      @nobundles = params[:nobundles]
      # if curnit.always_update is true 
      #   then use the external url when generating the config file
      # else
      #   generate a url to the curnit stored in the local cache
      curnit = @offering.curnit
      if curnit.always_update
        @curnit_url = curnit.url
      else
        @curnit_url = "#{request.protocol}#{request.host_with_port}#{ActionController::AbstractRequest.relative_url_root}/#{curnit.jar_public_path}"
      end

      # Create a hash of attributes, adding the url attributes last so they will overwrite any existing values
      @offering_attributes = Hash.new
      @offering.offerings_attributes.each do |at|
        @offering_attributes[at.name] = at.value
      end
      @url_params=request.query_parameters()
      @url_params.each do |k,v|
        # remove the last three chars of an &amp; enity if at start of key
        # see: hack warning comment in Offering config view (should be refactored)
        @offering_attributes[k[/(^amp;)*(.*)/, 2]] = v 
      end

      render :action => 'config', :layout => false
    rescue => e
      render(:text => e, :status => 404) # Not Found
    end
  end

  def bundle
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin 
        raise "bundle too large" if request.raw_post.length > BUNDLE_SIZE_LIMIT
        if request.env['HTTP_CONTENT_ENCODING'] == 'b64gzip'
          content = Zlib::GzipReader.new(StringIO.new(B64::B64.decode(request.raw_post))).read
        else
          content = request.raw_post
        end
        digest = Digest::MD5.hexdigest(content)
        if request.env['HTTP_CONTENT_MD5'] != nil
          if digest != request.env['HTTP_CONTENT_MD5']
            raise "Bundle MD5 Mismatch"
          end
        end
        #        pid = spawn do
        #          begin
        @bundle = Bundle.create!(:workgroup_id => params[:wid],
        :workgroup_version => params[:version], :bc => content)
        jobs = Bj.submit "./script/runner 'Bundle.find(#{@bundle.id}).process_bundle_contents'"
        #            exit(0)
        #          rescue
        #            logger.error("#{e}\n#{e.backtrace.join("\n")}")
        #          end
        #        end
        #        wait(pid)
        #        if $?.exitstatus != 0
        #          raise "Error saving bundle"
        #        end
        response.headers['Content-MD5'] = digest
        #        response.headers['Location'] = "#{url_for(:controller => 'bundle', :id => @bundle.id)}"
        response.headers['Cache-Control'] = 'public'
        render(:xml => "", :status => 201, :layout => false) # Created
      rescue Exception => e
        render(:text => "#{e}", :status => 400) # Bad Request
      end
    else
      begin
        @nobundles = params[:nobundles]
        @workgroup = @offering.workgroups.find_by_id(params[:wid])
        @portal = Portal.find(params[:pid])
        if @nobundles
          @bundles = []
        else
          @bundles = @workgroup.valid_bundles.asc
          if @portal.last_bundle_only
            # Bundles are no longer processed immediately, therefore socks aren't guaranteed to exist
            # even if the bundle has sockEntries. Scan the contents instead for sockEntries.
            # last_bundle_with_data = @bundles.reverse.detect { |b| b.socks.count > 0 }
            last_bundle_with_data = @bundles.reverse.detect { |b| b.bundle_content.content =~ /sockEntries/ }
            if last_bundle_with_data
              @bundles = [last_bundle_with_data]
            end
          end
        end
        response.headers["Content-Type"] = "text/xml"
        if @bundles.size > 0
          response.headers["last-modified"] = @bundles[-1].created_at
        end
        render :action => 'bundlelist', :layout => false
      rescue => e
        render(:text => e, :status => 404) # Not Found
      end
    end
  end

  def errorbundle_create
    if request.post?
      o = Offering.find(params[:id])
      @errorbundle = Errorbundle.new(params[:errorbundle])
      @errorbundle.offering_id = o.id
      if @errorbundle.create
        flash[:notice] = "Errorbundle #{@errorbundle.id} was successfully created."
      else
        flash[:notice] = "Error creating Errorbundle." 
      end
    else
      @errorbundle = Errorbundle.new
    end
  end

  def report_xls
    compact = params[:compact] ? true : false
    file = "#{RAILS_ROOT}/tmp/xls/#{@offering.id}.csv"
    pid = spawn {
      f = File.new(file, "w")
      f.write("")
      f.close
      debug = []
      pods = @offering.pods    
      pod_info = pods.collect { |p|
        if p.pas_type == 'note'
          if p.html_body != nil
            body = p.html_body.strip
          else
            body = nil
          end
          ["#{p.id}", "#{p.uuid}", "#{p.rim_name}", "#{body}"]
        else
          nil
        end
      }
      pod_info = pod_info.compact
      debug += ["In the method"]
      workgroup_ids = @offering.workgroups.collect {|w| w.id }
      offering_data = { }
      workgroup_ids.each do |wid|
        workgroup_data = { }
        w = Workgroup.find(wid)
        w.bundles.each do |b|
          debug += ["working with bundle #{b.id}"]
          b.socks.each do |s|
            debug += ["working with sock #{s.id}"]
            if s.pod.pas_type != 'note'
              debug += ["sock is not a note, skipping"]
              next
            end
            data = [s.bundle.id, s.bundle.sail_session_start_time.to_s, s.id, TimeTracker.seconds_to_s(s.ms_offset/1000), s.value]
            if compact
              metadata = "#{s.bundle.id}\r#{s.bundle.sail_session_start_time.to_s}\r#{s.id}\r#{TimeTracker.seconds_to_s(s.ms_offset/1000)}"
              data = [metadata, s.value]
            end
            if workgroup_data.has_key?("#{s.pod_id}")
              w_counter = 1

              # put the sock data in a new or existing dummy workgroup
              while (offering_data.has_key?("#{wid}|#{w_counter}") && offering_data["#{wid}|#{w_counter}"].has_key?(s.pod_id))
                w_counter += 1
              end
              if (offering_data.has_key?("#{wid}|#{w_counter}"))
                debug += ["The workgroup #{wid}|#{w_counter} exists, but doesn't have this pod data defined"]
                offering_data["#{wid}|#{w_counter}"]["#{s.pod_id}"] = data
              else
                debug += ["The workgroup #{wid}|#{w_counter} doesn't exist yet"]
                new_workgroup_data = { }
                new_workgroup_data["#{s.pod_id}"] = data
                offering_data["#{wid}|#{w_counter}"] = new_workgroup_data
              end
            else
              workgroup_data["#{s.pod_id}"] = data
            end
          end
        end
        offering_data["#{wid}"] = workgroup_data
      end 
      debug +=  [ offering_data ]

      # @workbook = Spreadsheet::Excel.new(file)
      # data_format = @workbook.add_format(:color=>"blue", :text_h_align=>1)
      # response.header_format = @workbook.add_format(:color=>"black", :bold=>1, :text_h_align=>1)
      # thick_bottom_border = @workbook.add_format(:bottom=>5)
      # thin_right_border = @workbook.add_format(:right=>1)
      # pod_info_merged_cells = @workbook.add_format()

      # notes_worksheet = @workbook.add_worksheet("Notes")
      # notes_worksheet.format_column(0, 8, format)

      row = 0
      col = 0
      # start with the headers for each pod
      pod_headers = ["Bundle ID", "Bundle Date", "Sock ID", "Sock Time", "Sock Content"]
      if compact
        pod_headers = ["Bundle ID\rBundle Date\rSock ID\rSock Time", "Content"]
      end
      # notes_worksheet.write(row, col, [["Pod ID", "Pod UUID", "Rim Name", "Note HTML Content", "Workgroup"]])
      pid_row = ["Pod ID"]
      puuid_row = ["Pod UUID"]
      rimname_row = ["Rim Name"]
      content_row = ["Note HTML Content"]
      header_row = ["Workgroup"]
      col = -4
      padding = [nil,nil,nil,nil]
      if compact
        padding = [nil]
      end
      pod_info.each do |p|
        # notes_worksheet.write(row, col += 5, [p])
        pid_row += [p[0]] + padding
        puuid_row += [p[1]] + padding
        rimname_row += [p[2]] + padding
        content_row += [p[3]] + padding
        header_row += pod_headers
      end
      offerings = offering_data.keys.sort
      CSV.open(file, "w") do |row|
        row << pid_row
        row << puuid_row
        row << rimname_row
        row << content_row
        row << header_row
        # row = 4
        offerings.each do |wid|
          # rename the dummy workgroups to match the real workgroup id
          debug += ["Found key #{wid}"]
          begin
            clean_wid = wid.split("|")[0]
          rescue
            clean_wid = wid
          end
          row_data = [clean_wid]
          pod_info.each do |p|
            if offering_data[wid] != nil && offering_data[wid].has_key?(p[0])
              # append the data to the row
              row_data += offering_data[wid][p[0]]
            else
              # pad the row with empty cells
              if compact
                row_data += [nil, nil]
              else
                row_data += [nil,nil,nil,nil,nil]
              end
            end
          end
          row << row_data
          # notes_worksheet.write(row += 1, 0, row_data)
        end
        # debug.each do |d|
        #   row << [d]
        # end
        row << []
      end
      exit(0)
    }
    wait(pid)
    # @workbook.close
    if $?.exitstatus != 0
      raise "Error generating spreadsheet"
    end
    send_data(File.open(file).read, :type => "application/vnd.ms.excel", :filename => "offering-report-#{@offering.id}.csv" )   
  end

  def curnitmap
    # find or create a curnitmap sailuser for this portal
    cm_user = SailUser.find(:first, :conditions => "first_name = 'curnitmap' AND portal_id = #{@portal.id}")
    if cm_user.blank?
      cm_user = SailUser.new()
      cm_user.first_name = "curnitmap"
      cm_user.last_name = "curnitmap"
      cm_user.portal = @portal
      begin
        cm_user.save!
      rescue => e
        render(:text => "#{e}", :status => 404)
        return
      end
    end
    # find or create curnitmap workgroup
    notdone = true
    @offering.workgroups.each do |w|
      if notdone
        w.members.each do |wm|
          if notdone && wm == cm_user
            @workgroup = w
            notdone = false
          end
        end
      end
    end

    if notdone
      @workgroup = Workgroup.create!(:offering => @offering, :name => "curnitmap", :version => 0, :portal => @portal)
      @workgroup.workgroup_memberships.create!(:sail_user_id => cm_user.id, :version => 0)
    end

    pdf_host = (request.env['HTTP_X_FORWARDED_SERVER'] ? request.env['HTTP_X_FORWARDED_SERVER'] : request.env['HTTP_HOST']) 
    pdf_relative_root = request.env['REQUEST_URI'].match(/(.*)\/[\d]+\/offering\/[\d]+[\/]?/)[1]
    @sdsBaseUrl = "http://#{pdf_host}#{pdf_relative_root}"  

    # request the curnitmap from the pdfserver
    cmap_url = "#{PDF_SITE_ROOT}/#{@portal.id}"
    cmap_url << "/offering/#{@offering.id}"
    cmap_url << "/workgroup/#{@workgroup.id}"
    cmap_url << "/curnitmap?sdsBaseUrl=#{@sdsBaseUrl}"
    cmap_url << "&curnitURL=#{@offering.curnit.url}"
    cmap_url = cmap_url.gsub(/([^:])\/+/, '\1/')
    begin
      open(cmap_url) do |cmap|
        if cmap.status[0] != "200"
          render(:text => "#{cmap.read}", :status => cmap.status[0])
        else
          # relay the response and file to the requestor
          send_data(cmap.read, :type => "application/xml", :filename => "curnitmap-#{@offering.id}.xml" )
        end
      end
    rescue OpenURI::HTTPError => error
      render(:text => "#{error.message}: #{error.io.read}", :status => error.io.status[0])
    rescue Timeout::Error => error
      render(:text => "Timeout on curnitmap generation: #{error.message}", :status => 408)
    end
  end


  def add_attribute
    @offering = Offering.find(params[:id])
    if request.post?
      @offering_attribute = OfferingsAttribute.new(params[:offering_attribute])
      @offering_attribute.offering = @offering
      if @offering_attribute.save
        flash[:notice] = "Offering attribute '#{@offering_attribute.name}' was successfully created."
        redirect_to :action => 'show'
      else
        flash[:notice] = "Error creating offering attribute."
      end
    end
  end

  def edit_attribute
    @offering = Offering.find(params[:id])
    @offering_attribute = OfferingsAttribute.find(params[:aid])
    if request.post?
      if @offering_attribute.update_attributes(params[:offering_attribute])
        flash[:notice] = "Offering attribute '#{@offering_attribute.name}' was successfully updated."
        redirect_to :action => 'show'
      else
        flash[:notice] = "Error updating offering attribute."
      end
    end
  end

  def remove_attribute
    @offering = Offering.find(params[:id])
    @offering_attribute = OfferingsAttribute.find(params[:aid])
    if @offering_attribute.destroy
      flash[:notice] = "Offering attribute '#{@offering_attribute.name}' was successfully removed."
    else
      flash[:notice] = "Error removing offering attribute."
    end
    redirect_to :action => 'show'
  end  

  protected 

  def compress 
    return unless request.get?    
    accepts = request.env['HTTP_ACCEPT_ENCODING'] 
    return unless accepts && accepts =~ /(x-gzip|gzip)/ 
    encoding = $1 
    output = StringIO.new 
    def output.close # Zlib does a close. Bad Zlib... 
      rewind 
    end 
    gz = Zlib::GzipWriter.new(output) 
    gz.write(response.body) 
    gz.close 
    if output.length < response.body.length 
      response.body = output.string 
      response.headers['Content-Encoding'] = encoding 
    end 
  end 
  
  def add_md5_checksum
    # It would be more effcient to do this at the http
    # server rather than in the app server
    if request.get?
      response.headers['Content-MD5'] = Digest::MD5.hexdigest(response.body)
    end
  end
end

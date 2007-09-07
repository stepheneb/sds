class OfferingController < ApplicationController

  require 'zlib'
  # require 'spreadsheet/excel'
  require 'csv'
  require 'open-uri'

  before_filter :log_referrer
  before_filter :find_offering, :except => [ :list, :create ]
  
  after_filter :compress, :only => [:bundle]

  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 2**21-1 # 2M  

  protected
  
  def find_offering
    @offering = find_portal_resource('Offering', params[:id])
  end  

  public
  
  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @offering = Offering.new(xml_parms)
        @offering.curnit = Curnit.find(xml_parms['curnit_id'])
        @offering.jnlp = Jnlp.find(xml_parms['jnlp_id'])
        if @offering.save
          response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
          render(:xml => "", :status => 201) # Created
        else
          errors =  @offering.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
          render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
        end
    else
      @offerings = @portal.offerings
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@offerings.empty? ? "<offerings />" : @offerings.to_xml(:except => ['created_at', 'updated_at'])) }
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
    else
      case params[:type]
      when 'user'
        @workgroup = SailUser.find(params[:uid]).workgroup
      when 'workgroup'
        @workgroup = Workgroup.find(params[:wid])
      end
      @savedata = params[:savedata]
      # need last mod?
      @headers["Content-Type"] = "application/x-java-jnlp-file"
      @headers["Cache-Control"] = "max-age=1"
      # look for any dynamically added jnlp parameters
      # jnlp_filename's value is used by the sds when it constructs the Content-Disposition header
      jnlp_filename = request.query_parameters['jnlp_filename'] || "#{to_filename(@jnlp.name)}_#{to_filename(@offering.curnit.name)}.jnlp"
      # this is a bit of a hack because the real query_parameters are not a hash
      # so I delete the jnlp_filename parameter if it exists in request.query_string
      request.query_string.gsub!(/[?&]jnlp_filename=[^&]*/, '')
      @headers["Content-Disposition"] = "attachment; filename=#{jnlp_filename}"
      # jnlp_properties value is a string of key-value pairs in a url query-string format
      # in which the reserved characters 
      if request.query_parameters['jnlp_properties']
        @jnlp_properties = CGIMethods.parse_query_parameters(URI.unescape(request.query_parameters['jnlp_properties']))
        request.query_string.gsub!(/[?&]jnlp_properties=[^&]*/, '')
      end
      render :action => 'jnlp', :layout => false
    end
  end
  
  def atom
#    @offering = Offering.find(params[:id])
#    @workgroups = @offering.workgroups
#    @headers["Content-Type"] = "application/atom+xml"
  end
  
  def config
    begin
      @offering = Offering.find(params[:id])
      @workgroup = Workgroup.find(params[:wid])
      @version = params[:version]
      @savedata = params[:savedata]
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
          content = Zlib::GzipReader.new(StringIO.new(Base64.decode64(request.raw_post))).read
        else
          content = request.raw_post
        end
        @bundle = Bundle.create!(:workgroup_id => params[:wid],
          :workgroup_version => params[:version], :content => content, :bc => content)
        response.headers['Content-md5'] = Base64.b64encode(Digest::MD5.digest(@bundle.bundle_content.content))
#        response.headers['Location'] = "#{url_for(:controller => 'bundle', :id => @bundle.id)}"
        response.headers['Cache-Control'] = 'public'
        render(:xml => "", :status => 201, :layout => false) # Created
      rescue Exception => e
        render(:text => e, :status => 400) # Bad Request
      end
    else
      begin
        @workgroup = @offering.find_in_workgroups(params[:wid])
        @bundles = @workgroup.valid_bundles.asc
        @portal = Portal.find(params[:pid])
        if @portal.last_bundle_only
          last_bundle_with_data = @bundles.reverse.detect { |b| b.socks.length > 0 }
          if last_bundle_with_data
            @bundles = [last_bundle_with_data]
          end
        end
        @headers["Content-Type"] = "text/xml"
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
	  file = "#{RAILS_ROOT}/tmp/xls/#{@offering.id}.csv"
	  f = File.new(file, "w")
	  f.write("")
	  f.close
	  debug = []
	  
	  pod_info = @offering.curnit.pods.collect { |p|
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
	  @offering_data = { }
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
				
				if workgroup_data.has_key?("#{s.pod_id}")
					w_counter = 1
					
					# put the sock data in a new or existing dummy workgroup
					while (@offering_data.has_key?("#{wid}|#{w_counter}") && @offering_data["#{wid}|#{w_counter}"].has_key?(s.pod_id))
						w_counter += 1
					end
					if (@offering_data.has_key?("#{wid}|#{w_counter}"))
						debug += ["The workgroup #{wid}|#{w_counter} exists, but doesn't have this pod data defined"]
						@offering_data["#{wid}|#{w_counter}"]["#{s.pod_id}"] = data
					else
						debug += ["The workgroup #{wid}|#{w_counter} doesn't exist yet"]
						new_workgroup_data = { }
						new_workgroup_data["#{s.pod_id}"] = data
						@offering_data["#{wid}|#{w_counter}"] = new_workgroup_data
					end
				else
					workgroup_data["#{s.pod_id}"] = data
				end
			end
		end
		@offering_data["#{wid}"] = workgroup_data
	  end	
	  debug +=  [ @offering_data ]
	  
	  # @workbook = Spreadsheet::Excel.new(file)
	  # data_format = @workbook.add_format(:color=>"blue", :text_h_align=>1)
	  # header_format = @workbook.add_format(:color=>"black", :bold=>1, :text_h_align=>1)
	  # thick_bottom_border = @workbook.add_format(:bottom=>5)
	  # thin_right_border = @workbook.add_format(:right=>1)
	  # pod_info_merged_cells = @workbook.add_format()
	  
	  # notes_worksheet = @workbook.add_worksheet("Notes")
	  # notes_worksheet.format_column(0, 8, format)
	  
	  row = 0
	  col = 0
	  # start with the headers for each pod
	  # notes_worksheet.write(row, col, [["Pod ID", "Pod UUID", "Rim Name", "Note HTML Content", "Workgroup"]])
	  pid_row = ["Pod ID"]
	  puuid_row = ["Pod UUID"]
	  rimname_row = ["Rim Name"]
	  content_row = ["Note HTML Content"]
	  header_row = ["Workgroup"]
	  col = -4
	  pod_info.each do |p|
	  	# notes_worksheet.write(row, col += 5, [p])
	  	pid_row += [p[0],nil,nil,nil,nil]
		puuid_row += [p[1],nil,nil,nil,nil]
		rimname_row += [p[2],nil,nil,nil,nil]
		content_row += [p[3],nil,nil,nil,nil]
		header_row += ["Bundle ID", "Bundle Date", "Sock ID", "Sock Time", "Sock Content"]
	  end
	  offerings = @offering_data.keys.sort
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
	  		if @offering_data[wid] != nil && @offering_data[wid].has_key?(p[0])
	  			# append the data to the row
				row_data += @offering_data[wid][p[0]]
	  		else
	  			# pad the row with empty cells
	  			row_data += [nil,nil,nil,nil,nil]
	  		end
	  	end
		row << row_data
		# notes_worksheet.write(row += 1, 0, row_data)
	  end
	  # debug.each do |d|
	  # 	row << [d]
	  # end
	  row << []
	  end
	  
	  # @workbook.close
	  send_data(File.open(file).read, :type => "application/vnd.ms.excel", :filename => "#{@offering.id}.csv" )  	
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
		@workgroup = Workgroup.create!(:offering => @offering, :name => "curnitmap")
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
		render(:text => "Bad response code on curnitmap generation: #{error.message}", :status => error.io.status[0])
	end
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

end

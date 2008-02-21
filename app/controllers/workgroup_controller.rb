class WorkgroupController < ApplicationController
  require 'pas_model_activity_lib'
  include PasModelActivityLib

  layout "standard", :except => [ :atom ] 
  before_filter :find_workgroup, :except => [ :list, :create, :list_by_offering ]

  protected
  
  def find_workgroup
    @workgroup = find_portal_resource('Workgroup', params[:id])
  end  

  public
  
  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      xml_parms = ConvertXml.xml_to_hash(request.raw_post)
      @workgroup = Workgroup.new(xml_parms)
      @workgroup.offering = Offering.find(xml_parms['offering_id'])
      @workgroup.portal = @portal
      if @workgroup.save
        response.headers['Location'] = url_for(:action => :show, :id => @workgroup.id)
        render(:xml => "", :status => 201) # Created
      else
        errors =  @workgroup.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
        render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
      end
    else
      respond_to do |wants|
        wants.html
        wants.xml { 
          workgroups = Workgroup.find(:all, :conditions => ['sds_workgroups.portal_id = ?', @portal.id])
          render :xml => (workgroups.empty? ? "<workgroups />" : workgroups.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end
  
  def list_by_offering
      @workgroups = Offering.find(params[:oid]).workgroups
      respond_to do |wants|
        wants.html { render :action => 'list' }
        wants.xml { render :xml => (@workgroups.empty? ? "<workgroups />" :@workgroups.to_xml(:except => ['created_at', 'updated_at', 'offering-id'])) }
      end
  end

  def membership
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      @workgroup.version += 1
      members = ConvertXml.xml_to_hash(request.raw_post)['workgroup_membership'] || ''
      # a hack because ConvertXml only returns an array to iterate on if there are 2 or more members!
      case members.length
      when 0 
        nil
      when 1
        @workgroup.workgroup_memberships.create!(:sail_user_id => members['sail_user_id'], :version => @workgroup.version)
      else
        members.each do |m|
          @workgroup.workgroup_memberships.create!(:sail_user_id => m['sail_user_id'], :version => @workgroup.version)
        end
      end
      if @workgroup.save
        response.headers['Location'] = url_for(:action => :membership, :id => @workgroup.id)
        render(:xml => "", :status => 201) # Created
      else
        render(:text => e, :status => 400) # Bad Request
      end
    else
      version = params[:version] || @workgroup.version
      @members = @workgroup.sail_users.version(version) # array of SailUser objects
      @membership_array = WorkgroupMembership.find_all_in_workgroup(params[:id], version) # array of WorkgroupMembership objects
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => WorkgroupMembership.wg_array_to_xml(@membership_array) }
      end
    end
  end

  def edit
    begin
      if request.post?
        @workgroup.version += 1
        if @workgroup.update_attributes(params[:workgroup])
          users = params[:users]
          users.each do |u|
            @workgroup.workgroup_memberships.create!(:sail_user_id => u, :version => @workgroup.version)
          end
          flash[:notice] = "Workgroup #{@workgroup.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @workgroup = Workgroup.find(params[:id])
      end
    rescue
      flash[:notice] = "Workgroup #{@workgroup.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def create
    if request.post?
      begin
        parms = params[:workgroup].merge({ "portal_id" => params[:pid]}).merge({ "version" => "0"})
        @workgroup = Workgroup.new(parms)
        if @workgroup.save
          users = params[:users]
          users.each do |u|
            @workgroup.workgroup_memberships.create!(:sail_user_id => u, :version => @workgroup.version)
          end
          flash[:notice] = "Workgroup #{@workgroup.id} was successfully created."
          redirect_to :action => 'list'
        else
          flash[:notice] = "Error creating Workgroup."
        end
      rescue => e
        flash[:notice] = "Error creating Workgroup memberships."
        redirect_to :action => 'list'
      end
    else
      @workgroup = Workgroup.new
      if params[:oid]
        @workgroup.offering_id = params[:oid]
      end
    end
  end

  def show
    begin
      @members = @workgroup.sail_users.version(@workgroup.version) # array of SailUser objects
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @workgroup.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          if @workgroup.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
            response.headers['Location'] = url_for(:action => :show, :id => @workgroup.id)
            render(:xml => "", :status => 201) # Created
          else
            errors =  @workgroup.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
            render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
          end
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.delete?
        @workgroup.destroy
        render(:text => '', :status => 204) # No Content
      end
#    rescue => e
#      render(:text => e, :status => 404) # Not Found
    end
  end
  
  def report
    @members = @workgroup.sail_users.version(@workgroup.version) # array of SailUser objects
    @membership_array = WorkgroupMembership.find_all_in_workgroup(params[:id]) # array of WorkgroupMembership objects
  end

  def report_xls
    members = @workgroup.sail_users.version(@workgroup.version) # array of SailUser objects
    
    cmap = {}
    @workgroup.valid_bundles.each do |b|
      cmap.merge!(b.curnitmap){|k,old,new| old }
    end
    
    # Create the first worksheet which summarizes the workgroup information
    file = "#{RAILS_ROOT}/tmp/xls/workgroup-#{@workgroup.id}.xls"
    f = File.new(file, "w")
    f.write("")
    f.close
    
    workbook = Spreadsheet::Excel.new(file)
    format = workbook.add_format(:color=>"blue", :text_h_align=>1)
    wrap_format = workbook.add_format(:color=>"blue", :text_h_align=>1, :text_wrap=>1)
    time_format = workbook.add_format(:color=>"blue", :text_h_align=>1)
    header_format = workbook.add_format(:color=>"blue", :text_h_align=>1, :bold=>1, :bottom=>5, :text_wrap=>1 )
    
    worksheet = workbook.add_worksheet("Info")
    worksheet.format_column(0, 16, format)
    worksheet.format_column(1, 24, format)
    worksheet.format_column(2..3, 8, format)
    worksheet.format_column(4, 12, format)
    worksheet.format_column(5, 20, format)
    
    row = 0
    worksheet.write(row, 0, ["Workgroup:",@workgroup.name, "id:", @workgroup.id])
    worksheet.write(row += 1, 0, ["Members:", @workgroup.member_names.split(", "), "ids:", members.collect {|m| m.id} ])
    worksheet.write(row += @workgroup.member_names.split(", ").size, 0, ["Valid Sessions:", @workgroup.valid_bundles.count.to_s ])
    worksheet.write(row += 1, 0, ["Offering:", @workgroup.offering.name, "id:", @workgroup.offering.id ])
    worksheet.write(row += 1, 0, ["Curnit:", @workgroup.offering.curnit.name, "id:", @workgroup.offering.curnit.id, "last updated:", @workgroup.offering.curnit.jar_last_modified.to_s ])
    
    sequence_worksheet = workbook.add_worksheet("Sequence")
    sequence_worksheet.format_column(0, 10, format)   # bundle id
    sequence_worksheet.format_column(1, 12, format)   # sock entry id
    sequence_worksheet.format_column(2, 12, format)   # elapsed time
    sequence_worksheet.format_column(3, 12, format)   # action
    sequence_worksheet.format_column(4, 36, format)   # step uuid
    sequence_worksheet.format_column(5,  6, format)   # Activity #
    sequence_worksheet.format_column(6,  6, format)   # Step #
    sequence_worksheet.format_column(7, 40, format)   # Title

    generate_sequence_data(sequence_worksheet)
    
    notes_worksheet = workbook.add_worksheet("Notes")
    notes_worksheet.format_column(0,   8, format) # pod id
    notes_worksheet.format_column(1,  36, format) # pod uuid
    notes_worksheet.format_column(2,  16, format) # rim name
    notes_worksheet.format_column(3,   3, format) # activity num
    notes_worksheet.format_column(4,   3, format) # step num
    notes_worksheet.format_column(5,  30, format) # step title
    notes_worksheet.format_column(6,  30, format) # note html content
    notes_worksheet.format_column(7,  16, format) # session bundle id
    notes_worksheet.format_column(8,  32, format) # session bundle date
    notes_worksheet.format_column(9,   8, format) # sock id
    notes_worksheet.format_column(10, 16, format) # sock time
    notes_worksheet.format_column(11, 50, format) # sock content
    
    row = 0
    notes_worksheet.write(row, 0, ["Pod ID", "Pod UUID", "Rim Name", "Activity Number", "Step Number", "Step Title", "Note HTML Content", "Session Bundle ID", "Session Bundle Date", "Sock entry ID", "Sock Time", "Sock Content"])    
    podnotes = @workgroup.valid_bundles.collect {|b| b.socks.find_notes}.flatten.group_by {|s| s.pod}

    logger.info("#{cmap}")
    podnotes.each do |pod, socks|
      act_num = ""
      step_num = ""
      step_title = ""
      if (cmap != nil && cmap[pod.uuid] != nil)
        act_num = cmap[pod.uuid]['activity_number']
        step_num = cmap[pod.uuid]['step_number']
        step_title = cmap[pod.uuid]['title']
      end
      note_preamble = [pod.id, pod.uuid, pod.rim_name, act_num, step_num, step_title, pod.html_body]
      socks.each do |s|
        note_response = [s.bundle.id, s.bundle.sail_session_start_time.to_s, s.id, TimeTracker.seconds_to_s(s.ms_offset/1000), s.value]
#        debugger
        row += 1
        notes_worksheet.write(row, 0, note_preamble + note_response)
      end
    end

    # Create a worksheet for each mad sock
    @workgroup.bundles.each do |b|
      b.socks.find_model_activity_datasets.each do |s|
        create_mad_worksheet(workbook, s, [format, header_format, wrap_format])
      end
    end
    workbook.close
    send_data(File.open(file).read, :type => "application/vnd.ms.excel", :filename => "workgroup-#{@workgroup.id}.xls" )
  end
  
  def atom
    @workgroups = @portal.workgroups
    response.headers["Content-Type"] = "application/atom+xml"
  end

  def destroy
    id = params[:id]
    begin
      Workgroup.find(id).destroy
      flash[:notice] = "Workgroup #{id.to_s} was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Workgroup #{id.to_s}." 
    end
    redirect_to :action => :list
  end
  
  private
  
  def generate_sequence_data(ws)
    first = true
    row = 0
      @workgroup.bundles.asc.each do |b|
        cm = b.curnitmap
        if first
          ws.write(0,0, ["Bundle id", "Sock entry id", "Elapsed Time\r(hh:mm:ss)", "Action", "Step uuid", "Activity #", "Step #", "Title"])
          first = false
        end
        row += 1
        b.socks.by_time_asc.each do |s|
          uuid = s.pod.uuid
          pas_type = s.pod.pas_type
          # filter by pas type
          # navigation_log
          # session_state
          # note
          # model_activity_data
          # other
          step_uuids = []
          step_action = nil
          if pas_type == "navigation_log"
            log = REXML::Document.new(s.value).root
            step_uuids = [log.attributes['podUUID']]
            step_action = log.name
          elsif pas_type == "session_state"
            # these duplicate info in the navigation log
            # only really need to have one set of nav info, and session_state has a problem
            # step_uuids = s.value.split(' ')
            # step_action = "inside step"
          elsif pas_type == "curnit_map"
            next
          else
            step_uuids = [s.pod.uuid]
            step_action = s.pod.pas_type
          end
          count = 0
          step_uuids.each do |step_uuid|
            count += 1
            # logger.info("Step uuid is: #{step_uuid}")
            # logger.info("#{s.pod.uuid}|#{uuid}|#{s.pod.pas_type}")
            bid = b.id
            sid = s.id
            elapsed_time = custom_time_string(Time::Time.at(Float(s.ms_offset)/1000).getgm)
            # logger.info("ms offset: #{s.ms_offset}, time: #{Time::Time.at(Float(s.ms_offset)).getgm}, formatted: #{elapsed_time}")
            if count > 1
              bid = ""
              elapsed_time = ""
              sid = ""
            end
            if cm == nil || step_uuid == nil || step_uuid == "null" || cm[step_uuid] == nil
              ws.write(row += 1, 0, [bid,sid,elapsed_time,step_action,step_uuid])
            else
              act_num = cm[step_uuid]["activity_number"]
              step_num = cm[step_uuid]["step_number"]
              title = cm[step_uuid]["title"]
              ws.write(row += 1, 0, [bid,sid,elapsed_time,step_action,step_uuid,act_num,step_num,title])
            end
          end
        end
      end
  end  
  
end















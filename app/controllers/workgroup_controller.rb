class WorkgroupController < ApplicationController

  layout "standard", :except => [ :atom ] 
  before_filter :find_workgroup, :except => [ :list, :create ]

  protected
  
  def find_workgroup
    @workgroup = find_portal_resource('Workgroup', params[:id])
  end  

  public
  
  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]}).merge({ "version" => "0"})
      @workgroup = Workgroup.new(xml_parms)
      @workgroup.offering = Offering.find(xml_parms['offering_id'])
      if @workgroup.save
        response.headers['Location'] = url_for(:action => :show, :id => @workgroup.id)
        render(:xml => "", :status => 201) # Created
      else
        errors =  @workgroup.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
        render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
      end
    else
      @workgroups = @portal.workgroups
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@workgroups.empty? ? "<workgroups />" :@workgroups.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def membership
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        @workgroup.version += 1
        members = ConvertXml.xml_to_hash(request.raw_post)['workgroup_membership']
        # a hack because ConvertXml only returns an array to iterate on if there are 2 or more members!
        case members.length
        when 0 
          raise
        when 1
          @workgroup.workgroup_memberships.create!(:user_id => members['user_id'], :version => @workgroup.version)
        else
          members.each do |m|
            @workgroup.workgroup_memberships.create!(:user_id => m['user_id'], :version => @workgroup.version)
          end
        end
        @workgroup.save!
        response.headers['Location'] = url_for(:action => :membership, :id => @workgroup.id)
        render(:xml => "", :status => 201) # Created
      rescue => e
        render(:text => e, :status => 400) # Bad Request
      end
    else
      @members = @workgroup.sail_users.version(@workgroup.version) # array of SailUser objects
      @membership_array = WorkgroupMembership.find_all_in_workgroup(params[:id]) # array of WorkgroupMembership objects
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
            @workgroup.workgroup_memberships.create!(:user_id => u, :version => @workgroup.version)
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
            @workgroup.workgroup_memberships.create!(:user_id => u, :version => @workgroup.version)
          end
          flash[:notice] = "Workgroup #{@workgroup.id} was successfully created."
          redirect_to :action => 'list'
        else
          flash[:notice] = "Error creating Workgroup."
        end
      rescue
        flash[:notice] = "Error creating Workgroup memberships."
      end
    else
      @workgroup = Workgroup.new
    end
  end

  def show
    begin
      @members = @workgroup.sail_users.version(@workgroup.version) # array of SailUser objects
      @membership_array = WorkgroupMembership.find_all_in_workgroup(params[:id]) # array of WorkgroupMembership objects
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

  def atom
    @workgroups = @portal.workgroups
    @headers["Content-Type"] = "application/atom+xml"
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
  
end















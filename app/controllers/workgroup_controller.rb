class WorkgroupController < ApplicationController

  layout "standard", :except => [ :atom ] 
  
  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]}).merge({ "version" => "0"})
        @workgroup = Workgroup.new(xml_parms)
        @workgroup.offering = Offering.find(xml_parms['offering_id'])
        @workgroup.save!
        response.headers['Location'] = url_for(:action => :show, :id => @workgroup.id)
        render(:xml => "", :status => 201) # Created
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      @workgroups = Workgroup.find_all_in_portal(params[:pid])
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@workgroups.empty? ? "<workgroups />" :@workgroups.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def membership
    @workgroup = Workgroup.find(params[:id])
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
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      @members = @workgroup.users.version(@workgroup.version) # array of User objects
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
        @workgroup = Workgroup.find(params[:id])
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
        @workgroup = Workgroup.create!(parms)
        users = params[:users]
        users.each do |u|
          @workgroup.workgroup_memberships.create!(:user_id => u, :version => @workgroup.version)
        end
        flash[:notice] = "Workgroup #{@workgroup.id} was successfully created."
        redirect_to :action => 'list'
      rescue
        flash[:notice] = "Error creating Workgroup." 
        redirect_to :action => :list
      end
    else
      @workgroup = Workgroup.new
    end
  end

  def show
    begin
      p = Portal.find(params[:pid])
      @workgroup = p.find_in_workgroups(params[:id])
      @members = @workgroup.users.version(@workgroup.version) # array of User objects
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
          @workgroup.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @workgroup.save
            response.headers['Location'] = url_for(:action => :show, :id => @workgroup.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
        rescue
          render(:text => "", :status => 400) # Bad Request
        end
      elsif request.delete?
        @workgroup.destroy
        render(:text => "", :status => 204) # No Content
      end
#    rescue
#      render(:text => "", :status => 404) # Not Found
    end
  end

  def atom
    @workgroups = Workgroup.find_all_in_portal(params[:pid])
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















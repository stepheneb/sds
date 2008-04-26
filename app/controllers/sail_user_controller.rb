class SailUserController < ApplicationController

  layout "standard"

  before_filter :find_sail_user, :except => [ :list, :create ]
  
  protected
  
  def find_sail_user
    @sail_user = find_portal_resource('SailUser', params[:id])
  end
  
  public  
  
  def list
    if request.env['CONTENT_TYPE'] == "application/xml" # should only be a POST or PUT
      begin
        u = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        if request.post?
          @sail_user = SailUser.new(u)
          if @sail_user.save
            response.headers['Location'] = url_for(:action => :show, :id => @sail_user.id)
            render(:xml => "", :status => 201) # Created
          else
            errors =  @sail_user.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
            render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
          end
        else
          if request.put?
            @sail_user = SailUser.find(u['id'])
            if @sail_user.update_attributes(u)
              response.headers['Location'] = url_for(:action => :show, :id => @sail_user.id)
              render(:xml => "", :status => 200) # OK
            else
              errors =  @sail_user.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
              render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
            end
          else
            render(:text => "", :status => 400) # Bad Request
          end
        end
      rescue => e
        errors =  @sail_user.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
        render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
      end
    else
      @sail_users = SailUser.search(params[:search], params[:page], @portal)
      respond_to do |wants|
        wants.html
        wants.xml { 
          render :xml => (@sail_users.empty? ? "<sail_users />" : @sail_users.to_xml(:except => ['created_at', 'updated_at']))
        }
      end
    end
  end

  def edit
    begin
      if request.post?
        if @sail_user.update_attributes(params[:sail_user])
          flash[:notice] = "SailUser #{@sail_user.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @sail_user = SailUser.find(params[:id])
      end
    rescue
      flash[:notice] = "SailUser #{@sail_user.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def create
    if request.post?
      parms = params[:sail_user].merge({ "portal_id" => params[:pid]})
      @sail_user = SailUser.new(parms)
      if @sail_user.save
        flash[:notice] = "SailUser #{@sail_user.id} was successfully created."
        redirect_to :action => 'list'
      else
        flash[:notice] = "Error creating SailUser." 
      end
    else
      @sail_user = SailUser.new
    end
  end

  def show
    begin
      id = params[:id]
      if id.length == 36
        @sail_user = @portal.sail_users.find_by_uuid(id)
      else
        @sail_user = @portal.sail_users.find(id)
      end
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @sail_user.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          if @sail_user.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
            response.headers['Location'] = url_for(:action => :show, :id => @sail_user.id)
            render(:xml => "", :status => 201) # Created
          else
            errors =  @sail_user.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
            render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
          end
        rescue
          render(:text => '', :status => 400) # Bad Request
        end
      elsif request.delete?
#        @sail_user.destroy
        render(:text => '', :status => 204) # No Content
      end
    rescue => e
      render(:text => e, :status => 404) # Not Found
    end
  end
  
  def workgroups
    id = params[:id]
    if id.length == 36
      @sail_user = @portal.sail_users.find_by_uuid(id)
    else
      @sail_user = @portal.sail_users.find(id)
    end
    @workgroups =  @sail_user.workgroups.uniq
    respond_to do |wants|
      wants.html
      wants.xml { render :xml => @workgroups.empty? ? "<workgroups></workgroups>" : @workgroups.to_xml }
    end
  end
  
  def destroy
    id = params[:id]
    flash[:notice] = "Deleting of SailUsers not permitted yet." 
#    begin
#      SailUser.find(id).destroy
#      flash[:notice] = "SailUser #{id.to_s} was successfully deleted."
#    rescue
#      flash[:notice] = "Error deleting SailUser #{id.to_s}." 
#    end
    redirect_to :action => :list
  end

end

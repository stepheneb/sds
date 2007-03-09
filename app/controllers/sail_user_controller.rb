class UserController < ApplicationController

  layout "standard"

  before_filter :find_user, :except => [ :list ]
  
  protected
  
  def find_user
    @user = find_portal_resource('User', params[:id])
  end
  
  public  
  
  def list
    if request.env['CONTENT_TYPE'] == "application/xml" # should only be a POST or PUT
      begin
        u = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        if request.post?
          @user = User.new(u)
          if @user.save!
            response.headers['Location'] = url_for(:action => :show, :id => @user.id)
            render(:xml => "", :status => 201) # Created
          end
        else
          if request.put?
            @user = User.find(u['id'])
            @user.update_attributes(u)
            response.headers['Location'] = url_for(:action => :show, :id => @user.id)
            render(:xml => "", :status => 200) # OK
          else
            render(:text => "", :status => 400) # Bad Request
          end
        end
      rescue => e
        render(:text => e, :status => 400) # Bad Request
      end
    else
      @users = @portal.users
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@users.empty? ? "<users />" : @users.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def edit
    begin
      if request.post?
        if @user.update_attributes(params[:user])
          flash[:notice] = "User #{@user.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @user = User.find(params[:id])
      end
    rescue
      flash[:notice] = "User #{@user.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def create
    if request.post?
      begin
        parms = params[:user].merge({ "portal_id" => params[:pid]})
        @user = User.create!(parms)
        flash[:notice] = "User #{@user.id} was successfully created."
        redirect_to :action => 'list'
      rescue
        flash[:notice] = "Error creating User." 
        redirect_to :action => :list
      end
    else
      @user = User.new
    end
  end

  def show
    begin
      id = params[:id]
      if id.length == 36
        @user = @portal.users.find_by_uuid(id)
      else
        @user = @portal.users.find(id)
      end
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @user.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          @user.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @user.save
            response.headers['Location'] = url_for(:action => :show, :id => @user.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
        rescue
          render(:text => '', :status => 400) # Bad Request
        end
      elsif request.delete?
        @user.destroy
        render(:text => '', :status => 204) # No Content
      end
    rescue => e
      render(:text => e, :status => 404) # Not Found
    end
  end
  
  def destroy
    id = params[:id]
    begin
      SdsUser.find(id).destroy
      flash[:notice] = "User #{id.to_s} was successfully deleted."
    rescue
      flash[:notice] = "Error deleting User #{id.to_s}." 
    end
    redirect_to :action => :list
  end

end

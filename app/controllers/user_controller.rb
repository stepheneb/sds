class UserController < ApplicationController

  layout "standard"

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        u = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @user = User.new(u)
        if @user.save!
          response.headers['Location'] = url_for(:action => :show, :id => @user.id)
          render(:xml => "", :status => 201) # Created
        end
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      @users = User.find_all_in_portal(params[:pid])
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => @users.to_xml(:except => ['created_at', 'updated_at']) }
      end
    end
  end

  def edit
    begin
      if request.post?
        @user = User.find(params[:id])
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

  def new
   @user = User.new
  end

  def create
    begin
      u = params[:user].merge({ "portal_id" => params[:pid]})
      @user = User.create!(u)
      flash[:notice] = "User #{@user.id} was successfully created."
      redirect_to :action => 'list'
    rescue
      flash[:notice] = "Error creating User." 
      redirect_to :action => :list
    end
  end

  def show
    if User.exists?(params[:id])
      @user = User.find(params[:id])
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
          render(:text => "", :status => 400) # Bad Request
        end
      elsif request.delete?
        @user.destroy
        render(:text => "", :status => 204) # No Content
      end
    else
      render(:text => "", :status => 404) # Not Found
    end
  end
  
  def destroy
    id = params[:id]
    begin
      User.find(id).destroy
      flash[:notice] = "User #{id.to_s} was successfully deleted."
    rescue
      flash[:notice] = "Error deleting User #{id.to_s}." 
    end
    redirect_to :action => :list
  end

end

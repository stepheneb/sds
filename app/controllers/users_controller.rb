class UsersController < ApplicationController

  layout "standard"
  
  skip_before_filter :require_login_for_non_rest, :only => [:new, :create, :activate]
  skip_before_filter :find_portal
  
  before_filter :find_user, :only => [:edit, :destroy, :show, :update]
  
  access_rule 'admin', :only => [:index, :destroy]
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  # verify :method => :post, :only => [ :destroy, :create],
  #        :redirect_to => { :action => :index }

  def find_user
    begin
      @user = User.find(params[:id])
    rescue
      redirect_to :action => 'index'
    end
  end
  
  def index
    # FIXME This should use some sort of pagination
    respond_to do |wants|
      wants.html {
        @users = User.search(params[:search], params[:page])
      }
    end
  end
  
  def edit
    if current_user != @user
      # unless you're an admin, you can only look at your own details
      permission_required('admin')      
    end
  end

  def destroy
    @user.destroy
    redirect_to :action => 'index'
  end
  
  def show
    if current_user != @user
      # unless you're an admin, you can only look at your own details
      permission_required('admin')    
    end
  end
  
  # render new.rhtml
  def new
    @user = User.new
  end

  def create
    # only users with admin role can set roles for users
    unless current_user && current_user.has_role('admin')
      params[:user].delete(:role_ids)
    end
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user.save
    if @user.errors.empty?
      # don't automatically log them in. wait until they've activated
      # self.current_user = @user
      redirect_back_or_default(home_url)
      flash[:notice] = "Thanks for signing up! You'll need to activate your account before you can log in."
    else
      render :action => 'new'
    end
  end

  def update
    # If either the password field or the password_confirmation fields are blank
    # then remove both values from the hash 
    if params[:user][:password].blank? || params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end
    
    # only users with admin role can set roles for users
    unless current_user.has_role('admin')
      params[:user].delete(:role_ids)
    end
    
    if current_user != @user
      # unless you're an admin, you can only update your own details
      permission_required('admin')    
    end
    
    if @user.update_attributes(params[:user])
      flash[:notice] = 'User was successfully updated.'
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end
  
  def activate
    self.current_user = params[:activation_code].blank? ? false : User.find_by_activation_code(params[:activation_code])
    if logged_in? && !current_user.active?
      current_user.activate
      flash[:notice] = "Signup complete!"
    end
    redirect_back_or_default(home_url)
  end

end

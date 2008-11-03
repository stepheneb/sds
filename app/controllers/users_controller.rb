class UsersController < ApplicationController

  layout "standard"
  
  skip_before_filter :require_login_for_non_rest, :only => [:new, :create, :activate]
  skip_before_filter :find_portal
  
  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :index }

  def index
    # FIXME This should use some sort of pagination
    @users = User.find(:all)
  end
  
  def edit
    @user = User.find(params[:id])
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'index'
  end
  
  def show
    @user = User.find(params[:id])
  end
  
  # render new.rhtml
  def new
  end

  def create
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
    if request.post?   
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        redirect_to :action => 'index'
      else
        render :action => 'edit'
      end
    else
      redirect_to(action => :edit)
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

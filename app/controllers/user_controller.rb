class UserController < ApplicationController

  layout "standard"
    
  before_filter :check_authentication, :except => [:login]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @user_pages, @users = paginate :users, :per_page => 10
  end

  def login
    if request.post?
      begin
        self.current_user = User.authenticate(params[:login], params[:password])
        if current_user
          if params[:remember_me] == "1"
            self.current_user.remember_me
            cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
          end
          redirect_to :controller => 'home', :action => 'index', :pid => 1
        else
          flash[:notice]  = "Login unsuccessful, login or password incorrect."
          self.current_user = User.find_by_login('anonymous')
        end
      end
    else
      @user = User.new
    end
  end 

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_to :controller => "home"
  end   
    
  def register
    if request.post?
      @user = params[:user]
      if User.find_by_login(@user.login) || User.find_by_email(@user.email)
        flash[:notice]  = "The username: \"#{@user.login}\", or the email \"#{@user.email}\" is already being used. Please pick another."
        redirect_to :action => "login"
      else
        @user.save
        redirect_to :controller => "page"
      end
    else
      @user = User.new
    end
  end
  
  def edit
    if request.post?
      @user = User.find(params[:id])
      if @user.update_attributes(params[:user])
        flash[:notice] = 'User was successfully updated.'
        redirect_to :action => 'list'
      else
        render :action => 'edit'
      end
    else
      @user = User.find(params[:id])
    end
  end

  def destroy
    User.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
end

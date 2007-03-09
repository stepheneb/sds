class SdsUserController < ApplicationController

  layout "standard"
    
  before_filter :check_authentication, :except => [:login]

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @sds_user_pages, @sds_users = paginate :sds_users, :per_page => 10
  end

  def login
    if request.post?
      begin
        self.current_sds_user = SdsUser.authenticate(params[:login], params[:password])
        if current_sds_user
          if params[:remember_me] == "1"
            self.current_sds_user.remember_me
            cookies[:auth_token] = { :value => self.current_sds_user.remember_token , :expires => self.current_sds_user.remember_token_expires_at }
          end
          redirect_to :controller => 'home', :action => 'index', :pid => 1
        else
          flash[:notice]  = "Login unsuccessful, login or password incorrect."
          self.current_sds_user = SdsUser.find_by_login('anonymous')
        end
      end
    else
      @sds_user = SdsUser.new
    end
  end 

  def logout
    self.current_sds_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    redirect_to :controller => "home"
  end   
    
  def register
    if request.post?
      @sds_user = params[:sds_user]
      if SdsUser.find_by_login(@sds_user.login) || SdsUser.find_by_email(@sds_user.email)
        flash[:notice]  = "The sds_username: \"#{@sds_user.login}\", or the email \"#{@sds_user.email}\" is already being used. Please pick another."
        redirect_to :action => "login"
      else
        @sds_user.save
        redirect_to :controller => "page"
      end
    else
      @sds_user = SdsUser.new
    end
  end
  
  def edit
    if request.post?
      @sds_user = SdsUser.find(params[:id])
      if @sds_user.update_attributes(params[:sds_user])
        flash[:notice] = 'SdsUser was successfully updated.'
        redirect_to :action => 'list'
      else
        render :action => 'edit'
      end
    else
      @sds_user = SdsUser.find(params[:id])
    end
  end

  def destroy
    SdsUser.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
  
end

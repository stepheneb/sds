class UserController < ApplicationController

  layout "standard"
  before_filter :check_authentication, :except => [:login, :login_form, :login_or_register]

  def check_authentication 
    unless session[:user] 
      session[:intended_action] = action_name 
      session[:intended_controller] = controller_name 
      redirect_to :action => "login_form" 
    end
  end

  def login_form
    # execution follows with :view => login_form, :action => login_or_register
    @user = User.new
    render :action => 'login_form' # goes to login_or_register
  end

  def login
    # successful authentication continues with :view => page, :action => list
    begin
      session[:user] = User.authenticate(params[:email], params[:password])
      redirect_to :controller => 'offering', :action => 'list'
#      redirect_to :action => session[:intended_action], :controller => session[:intended_controller] 
    rescue 
      flash[:notice]  = "Login unsuccessful, email or password incorrect."
      redirect_to :action => "login_form"
    end 
  end

  def logout
    session[:user] = nil 
    redirect_to :controller => "offering"
  end

  def index
    list
    render :action => 'list'
  end

  def list
    @user_pages, @users = paginate :users, :per_page => 10
  end

  def show
    @user = User.find(params[:id])
  end

end

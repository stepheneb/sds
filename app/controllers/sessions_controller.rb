# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  
  layout "standard"
  
  skip_before_filter :require_login_for_non_rest
  skip_before_filter :find_portal

  # render new.rhtml
  def new
  end

  def create
    logout_keeping_session!
    user = User.authenticate(params[:login], params[:password])
    if user
      # Protects against session fixation attacks, causes request forgery
      # protection if user resubmits an earlier form using back
      # button. Uncomment if you understand the tradeoffs.
      # reset_session
      self.current_user = user
      new_cookie_flag = (params[:remember_me] == "1")
      handle_remember_cookie! new_cookie_flag
      if self.current_user.change_password
        flash[:notice] = "Logged in successfully but you will need to create a new password"
      else
        flash[:notice] = "Logged in successfully"
      end
      redirect_back_or_default(home_url)
      flash[:notice] = "Logged in successfully"
    else
      if (user == false)
        note_failed_signin(true)
      else
        note_failed_signin
      end
      @login       = params[:login]
      @remember_me = params[:remember_me]
      render :action => 'new'
    end
  end

  def destroy
    logout_killing_session!
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(home_url)
  end
  
  def show
    redirect_to(login_url)
  end
  
  def permission_denied
    render(:status => 403)
  end
  
  protected
    # Track failed login attempts
    def note_failed_signin(needs_activated = false)
      if needs_activated
        flash[:error] = "You will need to activate your account before you may log in. Please check your email at the address you provided."
      else
        flash[:error] = "Couldn't log you in as '#{params[:login]}'"
      end
      logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip}"
    end
end

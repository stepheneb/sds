module AuthenticatedSystem
  protected
    # Returns true or false if the sds_user is logged in.
    # Preloads @current_sds_user with the sds_user model if they're logged in.
    def logged_in?
      (@current_sds_user ||= session[:sds_user] ? SdsUser.find_by_id(session[:sds_user]) : :false).is_a?(SdsUser)
    end
    
    # Accesses the current sds_user from the session.
    def current_sds_user
      @current_sds_user if logged_in?
    end
    
    # Store the given sds_user in the session.
    def current_sds_user=(new_sds_user)
      session[:sds_user] = (new_sds_user.nil? || new_sds_user.is_a?(Symbol)) ? nil : new_sds_user.id
      @current_sds_user = new_sds_user
    end
    
    # Check if the sds_user is authorized.
    #
    # Override this method in your controllers if you want to restrict access
    # to only a few actions or if you want to check if the sds_user
    # has the correct rights.
    #
    # Example:
    #
    #  # only allow nonbobs
    #  def authorize?
    #    current_sds_user.login != "bob"
    #  end
    def authorized?
      true
    end

    # Filter method to enforce a login requirement.
    #
    # To require logins for all actions, use this in your controllers:
    #
    #   before_filter :login_required
    #
    # To require logins for specific actions, use this in your controllers:
    #
    #   before_filter :login_required, :only => [ :edit, :update ]
    #
    # To skip this in a subclassed controller:
    #
    #   skip_before_filter :login_required
    #
    def login_required
      username, passwd = get_auth_data
      self.current_sds_user ||= SdsUser.authenticate(username, passwd) || :false if username && passwd
      logged_in? && authorized? ? true : access_denied
    end
    
    # Redirect as appropriate when an access request fails.
    #
    # The default action is to redirect to the login screen.
    #
    # Override this method in your controllers if you want to have special
    # behavior in case the sds_user is not authorized
    # to access the requested action.  For example, a popup window might
    # simply close itself.
    def access_denied
      respond_to do |accepts|
        accepts.html do
          store_location
          redirect_to :controller => '/account', :action => 'login'
        end
        accepts.xml do
          headers["Status"]           = "Unauthorized"
          headers["WWW-Authenticate"] = %(Basic realm="Web Password")
          render :text => "Could't authenticate you", :status => '401 Unauthorized'
        end
      end
      false
    end  
    
    # Store the URI of the current request in the session.
    #
    # We can return to this location by calling #redirect_back_or_default.
    def store_location
      session[:return_to] = request.request_uri
    end
    
    # Redirect to the URI stored by the most recent store_location call or
    # to the passed default.
    def redirect_back_or_default(default)
      session[:return_to] ? redirect_to_url(session[:return_to]) : redirect_to(default)
      session[:return_to] = nil
    end
    
    # Inclusion hook to make #current_sds_user and #logged_in?
    # available as ActionView helper methods.
    def self.included(base)
      base.send :helper_method, :current_sds_user, :logged_in?
    end

    # When called with before_filter :login_from_cookie will check for an :auth_token
    # cookie and log the sds_user back in if apropriate
    def login_from_cookie
      return unless cookies[:auth_token] && !logged_in?
      sds_user = SdsUser.find_by_remember_token(cookies[:auth_token])
      if sds_user && sds_user.remember_token?
        sds_user.remember_me
        self.current_sds_user = sds_user
        cookies[:auth_token] = { :value => self.current_sds_user.remember_token , :expires => self.current_sds_user.remember_token_expires_at }
        flash[:notice] = "Logged in successfully"
      end
    end

  private
    # gets BASIC auth info
    def get_auth_data
      sds_user, pass = nil, nil
      # extract authorisation credentials 
      if request.env.has_key? 'X-HTTP_AUTHORIZATION' 
        # try to get it where mod_rewrite might have put it 
        authdata = request.env['X-HTTP_AUTHORIZATION'].to_s.split 
      elsif request.env.has_key? 'HTTP_AUTHORIZATION' 
        # this is the regular location 
        authdata = request.env['HTTP_AUTHORIZATION'].to_s.split  
      end 
       
      # at the moment we only support basic authentication 
      if authdata && authdata[0] == 'Basic' 
        sds_user, pass = Base64.decode64(authdata[1]).split(':')[0..1] 
      end 
      return [sds_user, pass] 
    end
end

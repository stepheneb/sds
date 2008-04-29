class BundleController < ApplicationController

  require 'zlib'

  before_filter :log_referrer
  before_filter :find_bundle, :except => [ :list ]

  after_filter :compress, :only => [:bundle]
  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 5**21-1 # 5M

  
  protected
  
  def find_bundle
    unless @bundle = find_portal_resource('Bundle', params[:id])
      resource_not_found('Bundle', params[:id])
    end
  end

  public
  
  def bundle
    if @bundle = @portal.bundles.find_by_id(params[:id])  
      if request.put? and (request.env['CONTENT_TYPE'] == "application/xml")
        begin 
          raise "bundle too large" if request.raw_post.length > BUNDLE_SIZE_LIMIT
          if request.env['HTTP_CONTENT_ENCODING'] == 'b64gzip'
            content = Zlib::GzipReader.new(StringIO.new(Base64.decode(request.raw_post))).read
          else
            content = request.raw_post
          end
          @bundle.bc = content
          @bundle.save!
          response.headers['Content-md5'] = Base64.folding_encode(Digest::MD5.digest(@bundle.bundle_content.content))
          response.headers['Location'] =  "#{url_for(:controller => :bundle, :id => @bundle.id)}"
  #        response.headers['Cache-Control'] = 'no-cache'
          response.headers['Cache-Control'] = 'public'
          render(:xml => "", :status => 200) # updated
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.get?
        response.headers["Content-Type"] = "text/xml"
        render :text => @bundle.bundle_content.content, :layout => false
      else
        render(:text => "Forbidden: request not allowed. Only PUT and GET requests are allowed.", :status => 403) # Forbidden
      end
    else
      render(:text => "Not Found", :status => 404) # Not Found
    end
  end

end
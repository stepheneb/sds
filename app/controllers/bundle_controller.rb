class BundleController < ApplicationController

  require 'zlib'

  before_filter :log_referrer
  before_filter :find_bundle, :except => [ :list ]

  after_filter :compress, :only => [:bundle]
  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 5**21-1 # 5M

  
  protected
  
  def find_bundle
    # let's not burden the SDS down by forcing it to find *all* the bundles in a portal first,
    # esp. if we already know the bundle id
    begin
      @bundle = Bundle.find(params[:id])
      raise "incorrect portal" if @bundle.workgroup.portal_id != @portal.id
    rescue
      resource_not_found('Bundle', params[:id])
    end
  end

  public
  
  def ot_learner_data
    if @bundle.socks.count > 0
      @ot_learner_data = @bundle.bundle_content.ot_learner_data
    else
      @ot_learner_data =  @bundle.workgroup.blank_ot_learner_data
    end
    respond_to do |format|
      format.html { render :xml => @ot_learner_data }
      format.xml  { render :xml => @ot_learner_data }
    end
  end

  def bundle
    if @bundle
      if request.put? and (request.env['CONTENT_TYPE'] == "application/xml")
        begin 
          raise "bundle too large" if request.raw_post.length > BUNDLE_SIZE_LIMIT
          if request.env['HTTP_CONTENT_ENCODING'] == 'b64gzip'
            content = Zlib::GzipReader.new(StringIO.new(B64::B64.decode(request.raw_post))).read
          else
            content = request.raw_post
          end
          @bundle.bc = content
          @bundle.save!
          response.headers['Content-md5'] = B64::B64.folding_encode(Digest::MD5.digest(@bundle.bundle_content.content))
          response.headers['Location'] =  "#{url_for(:controller => :bundle, :id => @bundle.id)}"
  #        response.headers['Cache-Control'] = 'no-cache'
          response.headers['Cache-Control'] = 'public'
          render(:xml => "", :status => 200) # updated
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.get?
        response.headers["Content-Type"] = "text/xml"
        respond_to do |format|
          format.html  { render :action => 'bundle', :layout => false }
          format.xml  { render :action => 'bundle', :layout => false }
        end
      else
        render(:text => "Forbidden: request not allowed. Only PUT and GET requests are allowed.", :status => 403) # Forbidden
      end
    else
      render(:text => "Not Found", :status => 404) # Not Found
    end
  end
  
  def copy
    # find the destination workgroup
    begin
      @workgroup = Workgroup.find(params[:wid])
    rescue
      resource_not_found('Workgroup', params[:wid])
    end
    
    if @workgroup == @bundle.workgroup
      # refuse to copy to the source workgroup
      render(:xml => "<xml>Not Modified</xml>", :status => 304)
    else
      begin
        @bundle.copy_bundle(@workgroup)
        render(:xml => "<success/>", :status => 201)
      rescue => e
        render(:xml => "<xml><error>#{e}</error><backtrace>#{e.backtrace.join("\n")}</backtrace></xml>", :status => 400)
      end
    end
  end

end
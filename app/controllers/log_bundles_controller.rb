class LogBundlesController < ApplicationController

  require 'zlib'
  require 'cgi'
  
  before_filter :log_referrer
  before_filter :setup_vars
  
  layout "standard"
  
  BUNDLE_SIZE_LIMIT = 2**21-1
  
  def setup_vars
    # set the portal, offering, workgroup
    @portal = Portal.find(params[:pid])
    @offering = Offering.find(params[:id])
    @workgroup = Workgroup.find(params[:wid])
  end
  
  # GET /log_bundles
  # GET /log_bundles.xml
  def index
    # @log_bundles = []
    if request.post?
      create
    else
      @log_bundles = LogBundle.find(:all, :conditions => ["workgroup_id = ?", @workgroup.id])
  
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @log_bundles }
      end
    end
  end

  # GET /log_bundles/1
  # GET /log_bundles/1.xml
  def show
    @log_bundle = LogBundle.find(params[:lid])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @log_bundle }
    end
  end

# NOT REALLY SUPPORTED
  # GET /log_bundles/new
  # GET /log_bundles/new.xml
  def new
    @log_bundle = LogBundle.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @log_bundle }
    end
  end

# NOT SUPPORTED
  # GET /log_bundles/1/edit
#  def edit
#    @log_bundle = LogBundle.find(params[:id])
#  end

  # POST /log_bundles
  # POST /log_bundles.xml
  def create
    if (request.env['CONTENT_TYPE'] == "application/xml")
      @log_bundle = LogBundle.new()
      begin 
        raise "bundle too large" if request.raw_post.length > BUNDLE_SIZE_LIMIT
        if request.env['HTTP_CONTENT_ENCODING'] == 'b64gzip'
          content = Zlib::GzipReader.new(StringIO.new(Base64.decode64(request.raw_post))).read
        else
          content = request.raw_post
        end
        digest = Digest::MD5.hexdigest(content)
        if request.env['HTTP_CONTENT_MD5'] != nil
          if digest != request.env['HTTP_CONTENT_MD5']
            raise "Bundle MD5 Mismatch"
            end
        end
        response.headers['Content-md5'] = digest
        response.headers['Cache-Control'] = 'public'
        
        @log_bundle.content = content
        @log_bundle.workgroup_id = @workgroup.id
        
        if @log_bundle.save
          render(:xml => "", :status => :created, :location => url_for(:action => "show", :lid => @log_bundle.id))
        else
          render(:xml => @log_bundle.errors, :status => 400)
        end
      rescue Exception => e
        render(:xml => "#{e}", :status => 404)
        # render(:text => "#{e}", :status => 400) # Bad Request
      end
    else
      @log_bundle = LogBundle.new(params)
      @log_bundle.content = content
      @log_bundle.workgroup_id = @workgroup.id
    
      if @log_bundle.save
        flash[:notice] = 'LogBundle was successfully created.'
        redirect_to(:action => "show", :lid => @log_bundle.id)
      else
        render :action => "new"
      end
    end
  end

# NOT SUPPORTED
  # PUT /log_bundles/1
  # PUT /log_bundles/1.xml
#  def update
#    @log_bundle = LogBundle.find(params[:id])

#    respond_to do |format|
#      if @log_bundle.update_attributes(params[:log_bundle])
#        flash[:notice] = 'LogBundle was successfully updated.'
#        format.html { redirect_to(@log_bundle) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @log_bundle.errors, :status => :unprocessable_entity }
#      end
#    end
#  end

# NOT SUPPORTED
  # DELETE /log_bundles/1
  # DELETE /log_bundles/1.xml
 # def destroy
    # disabled for now
    # @log_bundle = LogBundle.find(params[:id])
    # @log_bundle.destroy

    # respond_to do |format|
    #   format.html { redirect_to(log_bundles_url) }
    #   format.xml  { head :ok }
    # end
#  end
end

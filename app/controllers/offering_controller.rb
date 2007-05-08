class OfferingController < ApplicationController

  require 'zlib'

  before_filter :log_referrer
  before_filter :find_offering, :except => [ :list, :create ]
  
  after_filter :compress, :only => [:bundle]

  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 2**21-1 # 2M  

  protected
  
  def find_offering
    @offering = find_portal_resource('Offering', params[:id])
  end  

  public
  
  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @offering = Offering.new(xml_parms)
        @offering.curnit = Curnit.find(xml_parms['curnit_id'])
        @offering.jnlp = Jnlp.find(xml_parms['jnlp_id'])
        if @offering.save
          response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
          render(:xml => "", :status => 201) # Created
        else
          errors =  @offering.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
          render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
        end
    else
      @offerings = @portal.offerings
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@offerings.empty? ? "<offerings />" : @offerings.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def edit
    if request.post?
      if @offering.update_attributes(params[:offering])
        flash[:notice] = "Offering #{@offering.id} was successfully updated."
        redirect_to :action => 'list'
      end
    else
      @offering = Offering.find(params[:id])
    end
  end

  def create
    if request.post?
      parms = params[:offering].merge({ "portal_id" => params[:pid]})
      @offering = Offering.new(parms)
      if @offering.save
        flash[:notice] = "Offering #{@offering.id} was successfully created."
        redirect_to :action => 'list'
      else
        flash[:notice] = "Error creating Offering." 
      end
    else
      @offering = Offering.new
    end
  end

  def show
    begin
      @offering = @portal.offerings.find(params[:id])
      if request.get?
        begin
          @sdsBaseUrl = "http://" << request.env['HTTP_HOST'] << (RAILS_RELATIVE_URL_ROOT ? "/#{RAILS_RELATIVE_URL_ROOT}" : "")
        rescue
          @sdsBaseUrl = "http://" << request.env['HTTP_HOST']
        end
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @offering.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          if @offering.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
            response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
            render(:xml => "", :status => 201) # Created
          else
            errors =  @offering.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
            render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
          end
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.delete?
        @offering.destroy
        render(:text => '', :status => 204) # No Content
      end
#    rescue => e
#      render(:text => e, :status => 404) # Not Found
    end
  end

  def destroy
#    id = params[:id]
#    begin
#      Offering.find(id).destroy
#      flash[:notice] = "Offering #{id.to_s} was successfully deleted."
#    rescue => e
#      flash[:notice] = "Error deleting Offering #{id.to_s}." 
#    end
#    redirect_to :action => :list
  end

  def jnlp
    @jnlp = @offering.jnlp
    if @jnlp.always_update || @jnlp.body.blank?
      @jnlp.save!
    end
    if @jnlp.body.blank?
      external_resource_not_found('Jnlp', @jnlp.id, @jnlp.url)
    else
      case params[:type]
      when 'user'
        @workgroup = SailUser.find(params[:uid]).workgroup
      when 'workgroup'
        @workgroup = Workgroup.find(params[:wid])
      end
      @savedata = params[:savedata]
      # need last mod?
      @headers["Content-Type"] = "application/x-java-jnlp-file"
      @headers["Cache-Control"] = "max-age=1"
      # look for any dynamically added jnlp parameters
      # jnlp_filename's value is used by the sds when it constructs the Content-Disposition header
      jnlp_filename = request.query_parameters['jnlp_filename'] || "#{to_filename(@jnlp.name)}_#{to_filename(@offering.curnit.name)}.jnlp"
      # this is a bit of a hack because the real query_parameters are not a hash
      # so I delete the jnlp_filename parameter if it exists in request.query_string
      request.query_string.gsub!(/[?&]jnlp_filename=[^&]*/, '')
      @headers["Content-Disposition"] = "attachment; filename=#{jnlp_filename}"
      # jnlp_properties value is a string of key-value pairs in a url query-string format
      # in which the reserved characters 
      if request.query_parameters['jnlp_properties']
        @jnlp_properties = CGIMethods.parse_query_parameters(URI.unescape(request.query_parameters['jnlp_properties']))
        request.query_string.gsub!(/[?&]jnlp_properties=[^&]*/, '')
      end
      render :action => 'jnlp', :layout => false
    end
  end
  
  def atom
#    @offering = Offering.find(params[:id])
#    @workgroups = @offering.workgroups
#    @headers["Content-Type"] = "application/atom+xml"
  end
  
  def config
    begin
      @offering = Offering.find(params[:id])
      @workgroup = Workgroup.find(params[:wid])
      @version = params[:version]
      @savedata = params[:savedata]
      render :action => 'config', :layout => false
    rescue => e
      render(:text => e, :status => 404) # Not Found
    end
  end
  
  def bundle
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin 
        raise "bundle too large" if request.raw_post.length > BUNDLE_SIZE_LIMIT
        if request.env['HTTP_CONTENT_ENCODING'] == 'b64gzip'
          content = Zlib::GzipReader.new(StringIO.new(Base64.decode64(request.raw_post))).read
        else
          content = request.raw_post
        end
        @bundle = Bundle.create!(:workgroup_id => params[:wid],
          :workgroup_version => params[:version], :content => content, :bc => content)
        response.headers['Content-md5'] = Base64.b64encode(Digest::MD5.digest(@bundle.bundle_content.content))
#        response.headers['Location'] = "#{url_for(:controller => 'bundle', :id => @bundle.id)}"
        response.headers['Cache-Control'] = 'public'
        render(:xml => "", :status => 201, :layout => false) # Created
      rescue => e
        render(:text => e, :status => 400) # Bad Request
      end
    else
      begin
        @workgroup = @offering.find_in_workgroups(params[:wid])
        @bundles = @workgroup.valid_bundles.asc
        @headers["Content-Type"] = "text/xml"
        render :action => 'bundlelist', :layout => false
      rescue => e
        render(:text => e, :status => 404) # Not Found
      end
    end
  end
  
  def errorbundle_create
    if request.post?
      o = Offering.find(params[:id])
      @errorbundle = Errorbundle.new(params[:errorbundle])
      @errorbundle.offering_id = o.id
      if @errorbundle.create
        flash[:notice] = "Errorbundle #{@errorbundle.id} was successfully created."
      else
        flash[:notice] = "Error creating Errorbundle." 
      end
    else
      @errorbundle = Errorbundle.new
    end
  end

  protected 

  def compress 
    return unless request.get?
    accepts = request.env['HTTP_ACCEPT_ENCODING'] 
    return unless accepts && accepts =~ /(x-gzip|gzip)/ 
    encoding = $1 
    output = StringIO.new 
    def output.close # Zlib does a close. Bad Zlib... 
      rewind 
    end 
    gz = Zlib::GzipWriter.new(output) 
    gz.write(response.body) 
    gz.close 
    if output.length < response.body.length 
      response.body = output.string 
      response.headers['Content-Encoding'] = encoding 
    end 
  end 

end

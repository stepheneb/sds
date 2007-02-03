class OfferingController < ApplicationController

  require 'zlib'

  before_filter :log_referrer
  after_filter :compress, :only => [:bundle]
  layout "standard", :except => [ :atom ] 

  BUNDLE_SIZE_LIMIT = 2**21-1 # 2M

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @offering = Offering.new(xml_parms)
        @offering.curnit = Curnit.find(xml_parms['curnit_id'])
        @offering.jnlp = Jnlp.find(xml_parms['jnlp_id'])
        if @offering.save!
          response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
          render(:xml => "", :status => 201) # Created
        end
#      rescue
#        render(:text => "", :status => 400) # Bad Request
      end
    else
      @offerings = Offering.find_all_in_portal(params[:pid])
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@offerings.empty? ? "<offerings />" : @offerings.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def edit
    begin
      if request.post?
        @offering = Offering.find(params[:id])
        if @offering.update_attributes(params[:offering])
          flash[:notice] = "Offering #{@offering.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @offering = Offering.find(params[:id])
      end
    rescue
      flash[:notice] = "Offering #{@offering.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def create
    if request.post?
      begin
        parms = params[:offering].merge({ "portal_id" => params[:pid]})
        @offering = Offering.create!(parms)
        flash[:notice] = "Offering #{@offering.id} was successfully created."
        redirect_to :action => 'list'
      rescue
        flash[:notice] = "Error creating Offering." 
        redirect_to :action => :list
      end
    else
      @offering = Offering.new
    end
  end

  def show
    begin
      p = Portal.find(params[:pid])
      @offering = p.offerings.find(params[:id])
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @offering.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          @offering.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @offering.save
            response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
#        rescue
#          render(:text => "", :status => 400) # Bad Request
        end
      elsif request.delete?
        @offering.destroy
        render(:text => "", :status => 204) # No Content
      end
#    rescue
#      render(:text => "", :status => 404) # Not Found
    end
  end

  def destroy
#    id = params[:id]
#    begin
#      Offering.find(id).destroy
#      flash[:notice] = "Offering #{id.to_s} was successfully deleted."
#    rescue
#      flash[:notice] = "Error deleting Offering #{id.to_s}." 
#    end
#    redirect_to :action => :list
  end

  def jnlp
    begin
      @offering = Offering.find(params[:id])
      case params[:type]
      when 'user'
        @workgroup = User.find(params[:uid]).workgroup
      when 'workgroup'
        @workgroup = Workgroup.find(params[:wid])
      end
      @savedata = params[:savedata]
      # need last mod?
      @headers["Content-Type"] = "application/x-java-jnlp-file"
#      @headers["Cache-Control"] = "no-cache"
      @headers["Cache-Control"] = "max-age=1"
      @headers["Content-Disposition"] = "attachment; filename=testjnlp.jnlp"
      filename = "testjnlp"
      render :action => 'jnlp', :layout => false
    rescue
      render(:text => "", :status => 404) # Not Found
    end
  end
  
  def atom
#    @offering = Offering.find(params[:id])
#    @workgroups = Workgroup.find_all_in_offering(@offering.id)
#    @headers["Content-Type"] = "application/atom+xml"
  end
  
  def config
    begin
      @offering = Offering.find(params[:id])
      @workgroup = Workgroup.find(params[:wid])
      @version = params[:version]
      @savedata = params[:savedata]
      render :action => 'config', :layout => false
    rescue
      render(:text => "", :status => 404) # Not Found
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
        @bundle = Bundle.create!(:offering_id => params[:id], :workgroup_id => params[:wid],
          :workgroup_version => params[:version], :content => content)
        response.headers['Content-md5'] = Base64.b64encode(Digest::MD5.digest(@bundle.content))
        response.headers['Location'] = url_for(:action => :bundle)
#        response.headers['Cache-Control'] = 'no-cache'
        response.headers['Cache-Control'] = 'public'
        render(:xml => "", :status => 201) # Created
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      begin
        @bundles = Bundle.find_by_offering_and_workgroup(params[:id], params[:wid])
        @headers["Content-Type"] = "text/xml"
        render :action => 'bundlelist', :layout => false
      rescue
        render(:text => "", :status => 404) # Not Found
      end
    end
  end


  def errorbundle
    if request.post?
      o = Offering.find(params[:id])
      @errorbundle = Errorbundle.new(params[:errorbundle].merge({ "ip_address" => request.env['REMOTE_HOST']}))
      @errorbundle.offering_id = o.id
      if @errorbundle.create
        response.headers['Content-md5'] = Base64.b64encode(Digest::MD5.digest(@errorbundle.data))
        response.headers['Location'] = url_for(:action => :errorbundle, :ebid => @errorbundle.id)
        render(:xml => "", :status => 201) # Created
      else
        render(:text => "", :status => 400) # Bad Request
      end
    else
      if request.get?
        @errorbundle = Errorbundle.find(params[:ebid])
        send_data(@errorbundle.data, :filename => @errorbundle.name, :type => @errorbundle.content_type, :disposition => 'inline')
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

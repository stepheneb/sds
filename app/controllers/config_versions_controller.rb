class ConfigVersionsController < ApplicationController
  
  skip_before_filter :find_portal
  layout "standard"
  
  require 'cgi'
  
  # GET /config_versions
  # GET /config_versions.xml
  def index
    @config_versions = ConfigVersion.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @config_versions }
    end
  end

  # GET /config_versions/1
  # GET /config_versions/1.xml
  def show
    @config_version = ConfigVersion.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @config_version }
    end
  end

  # GET /config_versions/new
  # GET /config_versions/new.xml
  def new
    @config_version = ConfigVersion.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @config_version }
    end
  end

  # GET /config_versions/1/edit
  def edit
    @config_version = ConfigVersion.find(params[:id])
  end

  # POST /config_versions
  # POST /config_versions.xml
  def create
    logger.info("Params: #{params}")
    if (request.env['CONTENT_TYPE'] == "application/xml")
      @config_version = ConfigVersion.new(ConvertXml.xml_to_hash(request.raw_post))
    else
      @config_version = ConfigVersion.new(params[:config_version])
    end

    respond_to do |format|
      if @config_version.save
        flash[:notice] = 'ConfigVersion was successfully created.'
        format.html { redirect_to(@config_version) }
        format.xml  { render :xml => @config_version, :status => :created, :location => @config_version }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @config_version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /config_versions/1
  # PUT /config_versions/1.xml
  def update
    @config_version = ConfigVersion.find(params[:id])

    respond_to do |format|
      success = false
      if (request.env['CONTENT_TYPE'] == "application/xml")
        success = @config_version.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
      else
        success = @config_version.update_attributes(params[:config_version])
      end
      if success
        flash[:notice] = 'ConfigVersion was successfully updated.'
        format.html { redirect_to(@config_version) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @config_version.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /config_versions/1
  # DELETE /config_versions/1.xml
  def destroy
 #   @config_version = ConfigVersion.find(params[:id])
#    @config_version.destroy

#    respond_to do |format|
#      format.html { redirect_to(config_versions_url) }
#      format.xml  { head :ok }
#    end
  end
end

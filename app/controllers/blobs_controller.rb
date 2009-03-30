class BlobsController < ApplicationController
  layout "standard"
  
  skip_before_filter :require_login_for_non_rest, :only => :raw
  skip_before_filter :find_portal
  
  # GET /blobs
  # GET /blobs.xml
  def index
    @blobs = Blob.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @blobs }
    end
  end

  # GET /blobs/:id/raw/:token
  def raw
    @blob = Blob.find(params[:id])
    
    if @blob && @blob.token == params[:token]
      type = params[:mimetype] ? params[:mimetype] : "application/octet-stream"
      send_data(@blob.content, :type => type, :filename => "file", :disposition => 'inline' )
    else
      render :text => "<error>Forbidden</error>", :status => :forbidden  # Forbidden
    end
  end
  
  # GET /blobs/1
  # GET /blobs/1.xml
  def show
    @blob = Blob.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @blob }
    end
  end

  # GET /blobs/new
  # GET /blobs/new.xml
  def new
#    @blob = Blob.new

    respond_to do |format|
#      format.html # new.html.erb
#      format.xml  { render :xml => @blob }
      format.html { head :forbidden }
    end
  end

  # GET /blobs/1/edit
  def edit
    @blob = Blob.find(params[:id])
    respond_to do |format|
      format.html { head :forbidden }
    end
  end

  # POST /blobs
  # POST /blobs.xml
  def create
    @blob = Blob.new(params[:blob])

    respond_to do |format|
#      if @blob.save
#        flash[:notice] = 'Blob was successfully created.'
#        format.html { redirect_to(@blob) }
#        format.xml  { render :xml => @blob, :status => :created, :location => @blob }
#      else
#        format.html { render :action => "new" }
#        format.xml  { render :xml => @blob.errors, :status => :unprocessable_entity }
#      end
      format.html { head :forbidden }
    end
  end

  # PUT /blobs/1
  # PUT /blobs/1.xml
  def update
    @blob = Blob.find(params[:id])

    respond_to do |format|
#      if @blob.update_attributes(params[:blob])
#        flash[:notice] = 'Blob was successfully updated.'
#        format.html { redirect_to(@blob) }
#        format.xml  { head :ok }
#      else
#        format.html { render :action => "edit" }
#        format.xml  { render :xml => @blob.errors, :status => :unprocessable_entity }
#      end
      format.html { head :forbidden }
    end
  end

  # DELETE /blobs/1
  # DELETE /blobs/1.xml
  def destroy
    respond_to do |format|
      format.html { redirect_to(blobs_url) }
      format.xml  { head :forbidden }
    end
  end
end

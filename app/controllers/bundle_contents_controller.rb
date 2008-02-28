class BundleContentsController < ApplicationController
  
  before_filter :find_bundle_contents, :except => [ :index, :new, :create ]

  protected
  
  def find_bundle_contents
    begin
      @bundle_content = BundleContent.find(params[:id])
      raise ActiveRecord::RecordNotFound unless @bundle_content.bundle.workgroup.offering.portal == @portal
    rescue ActiveRecord::RecordNotFound => error
      portal_resource_not_found(BundleContent, params[:id])
      false # returing false in a controller filter stops the chain of proccessing
    end
  end
  
  public
  
  # GET /bundle_contents
  # GET /bundle_contents.xml
  def index
    @bundle_content_count = BundleContent.count

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bundle_content_count }
    end
  end

  # GET /bundle_contents/1
  # GET /bundle_contents/1.xml
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bundle_content }
    end
  end

  def ot_learner_data
    @ot_learner_data = @bundle_content.ot_learner_data
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @ot_learner_data }
    end    
  end
  # GET /bundle_contents/new
  # GET /bundle_contents/new.xml
  def new
    @bundle_content = BundleContent.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bundle_content }
    end
  end

  # GET /bundle_contents/1/edit
  def edit
  end

  # POST /bundle_contents
  # POST /bundle_contents.xml
  def create
    @bundle_content = BundleContent.new(params[:bundle_content])

    respond_to do |format|
      if @bundle_content.save
        flash[:notice] = 'BundleContent was successfully created.'
        format.html { redirect_to(@bundle_content) }
        format.xml  { render :xml => @bundle_content, :status => :created, :location => @bundle_content }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bundle_content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bundle_contents/1
  # PUT /bundle_contents/1.xml
  def update
    respond_to do |format|
      if @bundle_content.update_attributes(params[:bundle_content])
        flash[:notice] = 'BundleContent was successfully updated.'
        format.html { redirect_to(@bundle_content) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bundle_content.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bundle_contents/1
  # DELETE /bundle_contents/1.xml
  def destroy
    @bundle_content = BundleContent.find(params[:id])
    @bundle_content.destroy

    respond_to do |format|
      format.html { redirect_to(bundle_contents_url) }
      format.xml  { head :ok }
    end
  end
end

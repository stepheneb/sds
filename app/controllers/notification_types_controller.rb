class NotificationTypesController < ApplicationController
  
  layout "standard"
  
  access_rule 'admin'
  
  skip_before_filter :find_portal
  
  # GET /notification_types
  # GET /notification_types.xml
  def index
    @notification_types = NotificationType.search(params[:search], params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notification_types }
    end
  end

  # GET /notification_types/1
  # GET /notification_types/1.xml
  def show
    @notification_type = NotificationType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @notification_type }
    end
  end

  # GET /notification_types/new
  # GET /notification_types/new.xml
  def new
    @notification_type = NotificationType.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @notification_type }
    end
  end

  # GET /notification_types/1/edit
  def edit
    @notification_type = NotificationType.find(params[:id])
  end

  # POST /notification_types
  # POST /notification_types.xml
  def create
    @notification_type = NotificationType.new(params[:notification_type])

    respond_to do |format|
      if @notification_type.save
        flash[:notice] = 'NotificationType was successfully created.'
        format.html { redirect_to(@notification_type) }
        format.xml  { render :xml => @notification_type, :status => :created, :location => @notification_type }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @notification_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /notification_types/1
  # PUT /notification_types/1.xml
  def update
    @notification_type = NotificationType.find(params[:id])

    respond_to do |format|
      if @notification_type.update_attributes(params[:notification_type])
        flash[:notice] = 'NotificationType was successfully updated.'
        format.html { redirect_to(@notification_type) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @notification_type.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_types/1
  # DELETE /notification_types/1.xml
  def destroy
    @notification_type = NotificationType.find(params[:id])
    @notification_type.destroy

    respond_to do |format|
      format.html { redirect_to(notification_types_url) }
      format.xml  { head :ok }
    end
  end
end

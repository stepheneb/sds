class NotificationListenersController < ApplicationController
  
  layout "standard"
  
  access_rule 'admin'
  
  skip_before_filter :find_portal
  
  # GET /notification_listeners
  # GET /notification_listeners.xml
  def index
    @notification_listeners = NotificationListener.search(params[:search], params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @notification_listeners }
    end
  end

  # GET /notification_listeners/1
  # GET /notification_listeners/1.xml
  def show
    @notification_listener = NotificationListener.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @notification_listener }
    end
  end

  # GET /notification_listeners/new
  # GET /notification_listeners/new.xml
  def new
    @notification_listener = NotificationListener.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @notification_listener }
    end
  end

  # GET /notification_listeners/1/edit
  def edit
    @notification_listener = NotificationListener.find(params[:id])
  end

  # POST /notification_listeners
  # POST /notification_listeners.xml
  def create
    @notification_listener = NotificationListener.new(params[:notification_listener])

    respond_to do |format|
      if @notification_listener.save
        flash[:notice] = 'NotificationListener was successfully created.'
        format.html { redirect_to(@notification_listener) }
        format.xml  { render :xml => @notification_listener, :status => :created, :location => @notification_listener }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @notification_listener.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /notification_listeners/1
  # PUT /notification_listeners/1.xml
  def update
    @notification_listener = NotificationListener.find(params[:id])

    respond_to do |format|
      if @notification_listener.update_attributes(params[:notification_listener])
        flash[:notice] = 'NotificationListener was successfully updated.'
        format.html { redirect_to(@notification_listener) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @notification_listener.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /notification_listeners/1
  # DELETE /notification_listeners/1.xml
  def destroy
    @notification_listener = NotificationListener.find(params[:id])
    @notification_listener.destroy

    respond_to do |format|
      format.html { redirect_to(notification_listeners_url) }
      format.xml  { head :ok }
    end
  end
end

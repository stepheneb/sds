class PortalController < ApplicationController

  layout "standard"

  skip_before_filter :find_portal

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        @portal = Portal.new(ConvertXml.xml_to_hash(request.raw_post))
        @portal.save!
        response.headers['Location'] = url_for(:action => :show, :id => @portal.id)
        render(:xml => "", :status => 201) # Created
      rescue => e
        render(:text => e, :status => 400) # Bad Request
      end
    else
      @portals = Portal.find(:all)
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@portals.empty? ? "<portals />" : @portals.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def edit
    begin
      if request.post?
        @portal = Portal.find(params[:id])
        if @portal.update_attributes(params[:portal])
          flash[:notice] = "Portal #{@portal.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @portal = Portal.find(params[:id])
      end
    rescue
      flash[:notice] = "Portal #{@portal.id} does not exist." 
      redirect_to :action => :list
    end
  end
  
  def create
    if request.post?
      begin
        @portal = Portal.create!(params[:portal])
        flash[:notice] = "Portal #{@portal.id} was successfully created."
        redirect_to :action => 'list'
      rescue
        flash[:notice] = "Error creating Portal." 
        redirect_to :action => :list
      end
    else
      @portal = Portal.new
    end
  end

  def show
    begin
      @portal = Portal.find(params[:id])
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @portal.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          @portal.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @portal.save
            response.headers['Location'] = url_for(:action => :show, :id => @portal.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
        rescue => e
          render(:text => e, :status => 400) # Bad Request
        end
      elsif request.delete?
        @portal.destroy
        render(:text => '', :status => 204) # No Content
      end
    rescue => e
      render(:text => e, :status => 404) # Not Found
    end
  end

#  def destroy
#    begin
#      Portal.find(params[:id]).destroy
#      flash[:notice] = "Portal #{@portal.id} was successfully deleted."
#    rescue
#      flash[:notice] = "Error deleting Portal #{@portal.id}." 
#      redirect_to :action => :list
#    end
#  end

end
 
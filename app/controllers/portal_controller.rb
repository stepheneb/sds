class PortalController < ApplicationController

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      @portal = Portal.new(process_portal_xml(request.raw_post))
      if @portal.save
        response.headers['Location'] = url_for(:action => :show, :id => @portal.id)
        render(:xml => "", :status => 201)
      else
        render(:text => "", :status => 404)
      end
    else
      @portals = Portal.find(:all)
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => @portals.to_xml(:except => ['created_at', 'updated_at']) }
      end
    end
  end
  
  def new
    @portal = Portal.new
    respond_to do |wants|
      wants.html
    end
  end

  def create
    @portal = Portal.new(params[:portal])
    if @portal.save
      flash[:notice] = 'Portal was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def show
    @portal = Portal.find(params[:id])
    respond_to do |wants|
      wants.html
      wants.xml  do
        response.headers['Location'] = url_for(:action => :show, :id => params[:id])
        render :xml => @portal.to_xml(:except => ['created_at', 'updated_at'])
      end
    end
  end

  def destroy
    Portal.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  private
  
  def process_portal_xml(portal_xml)
    s = portal_xml
    p = REXML::Document.new(s)
    return { 
      'name' => p.elements['/portal/name'].text,
      'auth_username' => p.elements['/portal/auth-username'].text,
      'auth_password' => p.elements['/portal/auth-password'].text
       }
  end
end


class JnlpController < ApplicationController

  layout "standard"

  def list
    begin
      raise unless request.post? || request.get?
      if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @jnlp = Jnlp.new(xml_parms)
        @jnlp.portal = Portal.find(xml_parms['portal_id'])
        @jnlp.save!
        response.headers['Location'] = url_for(:action => :show, :id => @jnlp.id)
        render(:xml => "", :status => 201) # Created
      else
        @jnlps = Jnlp.find_all_in_portal(params[:pid])
        respond_to do |wants|
          wants.html
          wants.xml { render :xml => (@jnlps.empty? ? "<jnlps />" : @jnlps.to_xml(:except => ['created_at', 'updated_at'])) }
        end
      end
    rescue
      render(:text => "", :status => 400) # Bad Request
    end
  end

  def edit
    begin
      if request.post?
        @jnlp = Jnlp.find(params[:id])
        if @jnlp.update_attributes(params[:jnlp])
          flash[:notice] = "Jnlp #{@jnlp.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @jnlp = Jnlp.find(params[:id])
      end
    rescue
      flash[:notice] = "Jnlp #{@jnlp.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def create
    if request.post?
      begin
        parms = params[:jnlp].merge({ "portal_id" => params[:pid]})
        @jnlp = Jnlp.create!(parms)
        flash[:notice] = "Jnlp #{@jnlp.id} was successfully created."
        redirect_to :action => 'list'
      rescue
        flash[:notice] = "Error creating Jnlp}." 
        redirect_to :action => :list
      end
    else
      @jnlp = Jnlp.new
    end
  end

  def show
    begin
      p = Portal.find(params[:pid])
      @jnlp = p.jnlps.find(params[:id])
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @jnlp.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          @jnlp.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @jnlp.save
            response.headers['Location'] = url_for(:action => :show, :id => @jnlp.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
        rescue
          render(:text => "", :status => 400) # Bad Request
        end
      elsif request.delete?
        @jnlp.destroy
        render(:text => "", :status => 204) # No Content
      end
    rescue
      render(:text => "", :status => 404) # Not Found
    end
  end
  
  def destroy
    id = params[:id]
    begin
      Jnlp.find(id).destroy
      flash[:notice] = "Jnlp #{id.to_s} was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Jnlp #{id.to_s}." 
    end
    redirect_to :action => :list
  end

end

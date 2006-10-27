class CurnitController < ApplicationController

  layout "standard"

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @curnit = Curnit.new(xml_parms)
        @curnit.portal = Portal.find(xml_parms['portal_id'])
        @curnit.save!
        response.headers['Location'] = url_for(:action => :show, :id => @curnit.id)
        render(:xml => "", :status => 201) # Created
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      @curnits = Curnit.find_all_in_portal(params[:pid])
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@curnits.empty? ? "<curnits />" : @curnits.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def edit
    begin
      if request.post?
        @curnit = Curnit.find(params[:id])
        if @curnit.update_attributes(params[:curnit])
          flash[:notice] = "Curnit #{@curnit.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @curnit = Curnit.find(params[:id])
      end
    rescue
      flash[:notice] = "Curnit #{@curnit.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def create
    if request.post?
      begin
        c = params[:curnit].merge({ "portal_id" => params[:pid]})
        @curnit = Curnit.create!(c)
        flash[:notice] = "Curnit #{@curnit.id} was successfully created."
        redirect_to :action => 'list'
      rescue
        flash[:notice] = "Error creating Curnit." 
        redirect_to :action => :list
      end
    else
      @curnit = Curnit.new
    end
  end

  def show
    begin
      p = Portal.find(params[:pid])
      @curnit = p.find_in_curnits(params[:id])
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @curnit.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          @curnit.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @curnit.save
            response.headers['Location'] = url_for(:action => :show, :id => @curnit.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
        rescue
          render(:text => "", :status => 400) # Bad Request
        end
      elsif request.delete?
        @curnit.destroy
        render(:text => "", :status => 204) # No Content
      end
    rescue
      render(:text => "", :status => 404) # Not Found
    end
  end

  def jnlp
    begin
      @curnit = Curnit.find(params[:id])
      @headers["Content-Type"] = "application/x-java-jnlp-file"
      @headers["Cache-Control"] = "public"
      @headers["Content-Disposition"] = "attachment; filename=testjnlp.jnlp"
      filename = "testjnlp"
      render :action => 'jnlp', :layout => false
    rescue
      render(:text => "", :status => 404) # Not Found
    end
  end
  
  def destroy
#    id = params[:id]
#    begin
#      Curnit.find(id).destroy
#      flash[:notice] = "Curnit #{id.to_s} was successfully deleted."
#    rescue
#      flash[:notice] = "Error deleting Curnit #{id.to_s}." 
#    end
#    redirect_to :action => :list
  end

end

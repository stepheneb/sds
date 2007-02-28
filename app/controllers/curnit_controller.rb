class CurnitController < ApplicationController

  layout "standard"
  
  before_filter :find_curnit, :except => [ :list ]
  
  protected
  
  def find_curnit
    @curnit = find_portal_resource('Curnit', params[:id])
  end
  
  public  

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @curnit = Curnit.new(xml_parms)
        @curnit.portal = Portal.find(xml_parms['portal_id'])
        @curnit.save!
        response.headers['Location'] = url_for(:action => :show, :id => @curnit.id)
        render(:xml => "", :status => 201) # Created
      rescue => e
        render(:text => e, :status => 400) # Bad Request
      end
    else
      @curnits = @portal.curnits
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => (@curnits.empty? ? "<curnits />" : @curnits.to_xml(:except => ['created_at', 'updated_at'])) }
      end
    end
  end

  def edit
    if @curnit = @portal.curnits.find_by_id(params[:id])
      if request.post?
        @curnit.update_attributes(params[:curnit])
        flash[:notice] = "Curnit #{@curnit.id} was successfully updated."
        redirect_to :action => 'list'
      end
    else
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
      rescue => e
        flash[:notice] = "Error creating Curnit." 
        redirect_to :action => :list
      end
    else
      @curnit = Curnit.new
    end
  end

  def show
    begin
      if @curnit = @portal.curnits.find_by_id(params[:id])
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
          rescue => e
            render(:text => e, :status => 400) # Bad Request
          end
        elsif request.delete?
          @curnit.destroy
          render(:text => '', :status => 204) # No Content
        end
      else
        render(:text => "Not Found", :status => 404) # Not Found
      end  
    rescue => e
      render(:text => e, :status => 400) # Bad Request
    end
  end
  
  def destroy
#    id = params[:id]
#    begin
#      Curnit.find(id).destroy
#      flash[:notice] = "Curnit #{id.to_s} was successfully deleted."
#    rescue => e
#      flash[:notice] = "Error deleting Curnit #{id.to_s}." 
#    end
#    redirect_to :action => :list
  end

end

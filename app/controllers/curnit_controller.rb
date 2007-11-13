class CurnitController < ApplicationController

  layout "standard"
  
  before_filter :find_curnit, :except => [ :list, :create ]
  
  protected
  
  def find_curnit
    @curnit = find_portal_resource('Curnit', params[:id])
  end
  
  public  

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      xml_parms = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
      begin
        @curnit = Curnit.new(xml_parms)
        @curnit.portal = Portal.find(xml_parms['portal_id'])
        if @curnit.save
          response.headers['Location'] = url_for(:action => :show, :id => @curnit.id)
          render(:xml => "", :status => 201) # Created
        else
           errors =  @curnit.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
           render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
        end
      rescue => e
        render(:text => "<validation-errors>\n<error>\n#{e.message}\n</error>\n</validation-errors>\n", :status => 400) # Bad Request
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
    if @curnit
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
      c = params[:curnit].merge({ "portal_id" => params[:pid]})
      begin
        @curnit = Curnit.new(c)
        if @curnit.save
          flash[:notice] = "Curnit #{@curnit.id} was successfully created."
          redirect_to :action => 'list'
        else
          flash[:notice] = "Error creating Curnit." 
        end
      rescue => ex
        flash[:notice] = "Error creating Curnit.\n\n<!-- #{ex}\n\n#{ex.backtrace.join("\n")} -->"
      end
    else
      @curnit = Curnit.new
    end
  end

  def show
    begin
      if @curnit
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
            if @curnit.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
              response.headers['Location'] = url_for(:action => :show, :id => @curnit.id)
              render(:xml => "", :status => 201) # Created
            else
              errors =  @curnit.errors.full_messages.collect {|e| "  <error>#{e}</error>\n"}.join
              render(:text => "<validation-errors>\n#{errors}</validation-errors>\n", :status => 400) # Bad Request
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

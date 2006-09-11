class OfferingController < ApplicationController

  layout "standard"

  def list
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        u = ConvertXml.xml_to_hash(request.raw_post).merge({"portal_id" => params[:pid]})
        @offering = Offering.new(u)
        if @offering.save!
          response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
          render(:xml => "", :status => 201) # Created
        end
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      @offerings = Offering.find_all_in_portal(params[:pid])
      respond_to do |wants|
        wants.html
        wants.xml { render :xml => @offerings.to_xml(:except => ['created_at', 'updated_at']) }
      end
    end
  end

  def edit
    begin
      if request.post?
        @offering = Offering.find(params[:id])
        if @offering.update_attributes(params[:offering])
          flash[:notice] = "Offering #{@offering.id} was successfully updated."
          redirect_to :action => 'list'
        end
      else
        @offering = Offering.find(params[:id])
      end
    rescue
      flash[:notice] = "Offering #{@offering.id} does not exist." 
      redirect_to :action => :list
    end
  end

  def new
   @offering = Offering.new
  end

  def create
    begin
      u = params[:offering].merge({ "portal_id" => params[:pid]})
      @offering = Offering.create!(u)
      flash[:notice] = "Offering #{@offering.id} was successfully created."
      redirect_to :action => 'list'
    rescue
      flash[:notice] = "Error creating Offering." 
      redirect_to :action => :list
    end
  end

  def show
    if Offering.exists?(params[:id])
      @offering = Offering.find(params[:id])
      if request.get?
        respond_to do |wants|
          wants.html
          wants.xml  do
            response.headers['Location'] = url_for(:action => :show, :id => params[:id])
            render :xml => @offering.to_xml(:except => ['created_at', 'updated_at'])
          end
        end
      elsif request.put?
        begin
          @offering.update_attributes(ConvertXml.xml_to_hash(request.raw_post))
          if @offering.save
            response.headers['Location'] = url_for(:action => :show, :id => @offering.id)
            render(:xml => "", :status => 201) # Created
          else
            raise
          end
        rescue
          render(:text => "", :status => 400) # Bad Request
        end
      elsif request.delete?
        @offering.destroy
        render(:text => "", :status => 204) # No Content
      end
    else
      render(:text => "", :status => 404) # Not Found
    end
  end

  def destroy
    id = params[:id]
    begin
      Offering.find(id).destroy
      flash[:notice] = "Offering #{id.to_s} was successfully deleted."
    rescue
      flash[:notice] = "Error deleting Offering #{id.to_s}." 
    end
    redirect_to :action => :list
  end

  def jnlp
    @offering = Offering.find(params[:id])
    @workgroup = Workgroup.find(params[:wid])
    @headers["Content-Type"] = "application/x-java-jnlp-file"
    @headers["Cache-Control"] = "public"
    @headers["Content-Disposition"] = "attachment; filename=testjnlp.jnlp"
    filename = "testjnlp"
    render :action => 'jnlp', :layout => false
  end
  
  def config
    @offering = Offering.find(params[:id])
    @workgroup = Workgroup.find(params[:wid])
    @version = params[:version]
    render :action => 'config', :layout => false
  end
  
  def bundle
    if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
      begin
        @bundle = Bundle.create!(
          :offering_id => params[:id],
          :workgroup_id => params[:wid],
          :workgroup_version => params[:version],
          :content => request.raw_post)
        response.headers['Location'] = url_for(:action => :bundle)
        render(:xml => "", :status => 201) # Created
      rescue
        render(:text => "", :status => 400) # Bad Request
      end
    else
      @bundles = Bundle.find_by_offering_and_workgroup(params[:id], params[:wid])
      @headers["Content-Type"] = "text/xml"
      render :action => 'bundlelist', :layout => false
    end
  end
     
end















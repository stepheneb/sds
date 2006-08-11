class JnlpController < ApplicationController

#  layout "standard"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
   if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
     @jnlp = Jnlp.new(process_jnlp_xml(request.raw_post))
     if @jnlp.save
       response.headers['Location'] = url_for(:action => :show, :id => @jnlp.id)
       render(:xml => "", :status => 201)
     else
       render(:text => "", :status => 404)
     end
   else
     @jnlps = Jnlp.find(:all, :conditions => ["portal_id = :pid", params])
     respond_to do |wants|
       wants.html
       wants.xml { render :xml => @jnlps.to_xml(:except => ['created_at', 'updated_at']) }
     end
   end
  end

  def new
   @jnlp = Jnlp.new
   respond_to do |wants|
     wants.html
     wants.xml do
       @jnlp.save
       response.headers['Location'] = url_for(:action => :jnlp, :id => @jnlp.id)
       render :xml => @jnlp.to_xml(:except => ['created_at', 'updated_at'])
     end
   end
  end

  def create
    j = params[:jnlp].merge({ "portal_id" => params[:pid]})
    @jnlp = Jnlp.new(j)
    if @jnlp.save
      flash[:notice] = 'Jnlp was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def show
    @jnlp = Jnlp.find(params[:pid])
    respond_to do |wants|
     wants.html
     wants.xml  do
       response.headers['Location'] = url_for(:action => :show, :id => params[:id])
       render :xml => @jnlp.to_xml(:except => ['created_at', 'updated_at'])
     end
    end
  end

  def destroy
   Jnlp.find(params[:id]).destroy
   redirect_to :action => 'list'
  end

  private

  def process_jnlp_xml(jnlp_xml)
   s = jnlp_xml
   j = REXML::Document.new(s)
   return { 
     'portal_id' => c.elements['/jnlp/portal_id'].text.to_i,
     'name' => c.elements['/jnlp/name'].text,
     'url' => c.elements['/jnlp/url'].text
      }
  end
end

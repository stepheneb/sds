class CurnitController < ApplicationController

#  layout "standard"

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
   if request.post? and (request.env['CONTENT_TYPE'] == "application/xml")
     @curnit = Curnit.new(process_curnit_xml(request.raw_post))
     if @curnit.save
       response.headers['Location'] = url_for(:action => :show, :id => @curnit.id)
       render(:xml => "", :status => 201)
     else
       render(:text => "", :status => 404)
     end
   else
#     breakpoint
     @curnits = Curnit.find(:all, :conditions => ["portal_id = :pid", params])
     respond_to do |wants|
       wants.html
       wants.xml { render :xml => @curnits.to_xml(:except => ['created_at', 'updated_at']) }
     end
   end
  end

  def new
   @curnit = Curnit.new
   respond_to do |wants|
     wants.html
   end
  end

  def create
    c = params[:curnit].merge({ "portal_id" => params[:pid]})
    @curnit = Curnit.new(c)
    if @curnit.save
      flash[:notice] = 'Curnit was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def show
    @curnit = Curnit.find(params[:id])
    respond_to do |wants|
     wants.html
     wants.xml  do
       response.headers['Location'] = url_for(:action => :show, :id => params[:id])
       render :xml => @curnit.to_xml(:except => ['created_at', 'updated_at'])
     end
    end
  end

  def destroy
   Curnit.find(params[:id]).destroy
   redirect_to :action => 'list'
  end

  private

  def process_curnit_xml(curnit_xml)
   s = curnit_xml
   c = REXML::Document.new(s)
   return { 
     'name' => c.elements['/curnit/name'].text,
     'url' => c.elements['/curnit/url'].text
      }
  end

end

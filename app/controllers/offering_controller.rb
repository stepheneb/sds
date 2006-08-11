class OfferingController < ApplicationController

  layout "standard"

  def index
    list
    render :action => 'list'
  end

  def list
   @offering_pages, @offerings = paginate :offerings, :per_page => 10
   params[:list_conditions] = 'all'
  end

  def show
    # execution follows with :view => show
    @offering = Offering.find(params[:id])
  end

  def jnlp
    @offering = Offering.find(params[:oid])
    @user = User.find(params[:uid])
    @headers["Content-Type"] = "application/x-java-jnlp-file"
    @headers["Cache-Control"] = "public"
    @headers["Content-Disposition"] = "attachment; filename=testjnlp.jnlp"
    filename = "testjnlp"
    render :action => 'jnlp', :layout => false
  end

  def config
    @offering = Offering.find(params[:oid])
    @user = User.find(params[:uid])
    render :action => 'config', :layout => false
  end

  def bundle
    if request.post?
      if (params[:oid] && params[:uid]) && Offering.exists?(params[:oid]) && User.exists?(params[:uid])
        @bundle = Bundle.create(
          :user_id => params[:uid],
          :offering_id => params[:oid],
          :content => request.raw_post
        )
        process_socks(@bundle.content, @bundle.id, @bundle.offering_id, @bundle.user_id)
        response.headers['Location'] = url_for(:action => :bundle, :oid => params[:oid], :bid => @bundle.id)
        render(:xml => "", :status => 201)
      else
        render(:text => "", :status => 404)
      end
    elsif request.delete?
      if params[:id]
        Bundle.destroy(params[:id])
        render(:text => "", :status => 204)
      else
        render(:text => "", :status => 404)
      end
    elsif request.put?
      if (params[:oid] && params[:uid]  && params[:bid]) && Offering.exists?(params[:oid]) && User.exists?(params[:uid]) && Bundle.exists?(params[:bid])
        @bundle = Bundle.find(params[:bid])
        @bundle.content = request.raw_post
        @bundle.save
        render(:text => "", :status => 204)
      else
        render(:text => "", :status => 404)
      end
    elsif (request.env['CONTENT_TYPE'] == "application/xml") || (request.env['HTTP_ACCEPT'] == "application/xml")
      @headers["Content-Type"] = "text/xml"
      if (params[:oid] && params[:uid]  && params[:bid]) && Offering.exists?(params[:oid]) && User.exists?(params[:uid]) && Bundle.exists?(params[:bid])
        @bundle = Bundle.find(params[:bid])
        render :action => 'bundle', :layout => false
      elsif (params[:oid] && params[:uid]) && Offering.exists?(params[:oid]) && User.exists?(params[:uid])
        @bundles = Bundle.find(:all, :conditions => ["offering_id = :oid and user_id = :uid", params])
        render :action => 'bundlelist', :layout => false
      else
        render(:text => "", :status => 404)
      end
    else
      list
      render :action => 'list'
    end
  end

  def new
    # execution follows with  :view => new, :action => create
    @offering = Offering.new
  end

  def create
    @offering = Offering.new(params[:offering])
    if session[:user]
      @offering.user = session[:user]
    else
      flash[:notice] = 'You must be logged in to create an offering.'
      redirect_to :action => 'list'
    end
    if @offering.save
      flash[:notice] = 'Offering was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    # execution follows with  :view => edit, :action => edit with request=post
    @offering = Offering.find(params[:id])
    if request.post?
      if @offering.update_attributes(params[:offering])
        flash[:notice] = 'Offering was successfully updated.'
        redirect_to :action => 'show', :id => @offering
      else
        render :action => 'edit'
      end     
    end
  end

  def destroy
    Offering.find(params[:id]).destroy
    redirect_to :action => 'list'
  end

  def bundlefix
    Bundle.find(:all).each do |b|
      process_socks(b.content, b.id, b.offering_id, b.user_id)
    end
    redirect_to :controller => 'offering', :action => 'index'
  end

  private

  def process_socks(content, bundle_id, offering_id, user_id)
    socks = REXML::Document.new(content).elements.to_a('//sockParts')
    socks.each do |s_xml|
      xml = REXML::Document.new(s_xml.elements["sockEntries"].attributes["value"])
      s = Sock.create(
        :user_id => user_id,
        :offering_id => offering_id,
        :bundle_id => bundle_id,
        :pod_uuid => s_xml.attributes["podId"].to_s,
        :rim_name => s_xml.attributes["rimName"].to_s,
        :ms_offset => s_xml.elements["sockEntries"].attributes["millisecondsOffset"].to_f,
        :value => xml.to_s
      )
      if s.rim_name == 'modelActivityData'
        create_model_activity_dataset(xml, bundle_id, offering_id, user_id)
      end
    end
  end

  def create_model_activity_dataset(xml, bundle_id, offering_id, user_id)
    dataset = ModelActivityDataset.create(
      :bundle_id => bundle_id,
      :offering_id => offering_id,
      :user_id => user_id,
      :name => xml.elements['/modelactivitydata/name'].get_text.to_s,
      :start_time => Float(xml.elements['/modelactivitydata/start_time'].get_text.to_s),
      :end_time => Float(xml.elements['/modelactivitydata/end_time'].get_text.to_s)
    )
    computational_input_list = []
    xml.elements.each('/modelactivitydata/computational_input') do |ci_xml|
      computational_input_list << find_computational_input_xml(ci_xml, dataset.id)
    end
    representational_type_list = []
    representational_attribute_list = []
    xml.elements.each('/modelactivitydata/representational_attribute') do |rt_xml|
      representational_type_list << find_representational_type_xml(rt_xml, dataset.id)
      rt_xml.elements.each('value_list/value') do |ra_xml|
        representational_attribute_list << find_representational_attribute_xml(ra_xml, representational_type_list.last.id)
      end
    end
    modelrun_list = []
    # model: model_activity_modelrun
    xml.elements.each("//modelrun") do |mr_xml|
      mr = ModelActivityModelrun.create(
        :model_activity_dataset_id => dataset.id,
        :start_time => Float(mr_xml.elements['start_time'].get_text.to_s),
        :end_time => Float(mr_xml.elements['end_time'].get_text.to_s)
      )
      modelrun_list << mr
      # model: computational_input_value
      mr_xml.elements.each('computational_input_value') do |civ_xml|
        ci_ref = civ_xml.attributes['reference'].to_s
        ci = computational_input_list.find { |c| c.name == ci_ref }
        civ = ComputationalInputValue.create(
          :model_activity_modelrun_id => modelrun_list.last.id,
          :computational_input_id => ci.id,
          :value => civ_xml.elements['value'].get_text.to_s
        )
      end
      # model: representational_value
      mr_xml.elements.each('representational_attribute_value') do |rv_xml|
        ra_ref = rv_xml.attributes['reference'].to_s
        ri = representational_attribute_list.find { |r| r.representational_type.name == ra_ref }
        rv = RepresentationalValue.create(
          :model_activity_modelrun_id => modelrun_list.last.id,
          :representational_attribute_id => ri.id
        )
      end
    end
    dataset.modelrun_count = modelrun_list.length
    dataset.computational_input_count = computational_input_list.length
    dataset.representational_type_count = representational_type_list.length
    dataset.save
  end

  def find_computational_input_xml(ci_xml, dataset_id)
    name = ci_xml.attributes["name"]
    units = ci_xml.elements['units'].get_text.to_s
    range_max = ci_xml.elements['range/max_value'].get_text.to_s
    range_min = ci_xml.elements['range/min_value'].get_text.to_s
    ci = ComputationalInput.find(:first, :conditions => ["model_activity_dataset_id = :dataset_id and 
      name = :name and units = :units and range_max = :range_max and range_min = :range_min", {:dataset_id => dataset_id, 
        :name => name, :units => units, :range_max => range_max, :range_min => range_min}])
    unless ci
      ci = ComputationalInput.create(:model_activity_dataset_id => dataset_id, 
        :name => name, :units => units, :range_max => range_max, :range_min => range_min)
    end
    ci
  end

  def find_representational_type_xml(rt_xml, dataset_id)
    name = rt_xml.attributes["name"].to_s
    rt = RepresentationalType.find(:first, :conditions => ["model_activity_dataset_id = :dataset_id and 
      name = :name", {:dataset_id => dataset_id, 
        :name => name}])
    unless rt
      rt = RepresentationalType.create(:model_activity_dataset_id => dataset_id, :name => name)
    end
    rt
  end

  def find_representational_attribute_xml(ra_xml, rt_id)
    value = ra_xml.text.to_s
    ra = RepresentationalAttribute.find(:first, :conditions => ["representational_type_id = :rt_id and 
      value = :value", {:rt_id => rt_id, :value => value}])
    unless ra
      ra = RepresentationalAttribute.create(:representational_type_id => rt_id, :value => value)
    end
    ra
  end
end
















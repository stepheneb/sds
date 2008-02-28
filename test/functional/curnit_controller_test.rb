require File.dirname(__FILE__) + '/../test_helper'

class CurnitControllerTest < ActionController::TestCase
  # once rails 2.0.3 is released, we can use this
  # and not have to call it in each test
  # setup :setup_vars
  
  # FIXME: assert_tag looks directly at the rendered view's xml/html structure
  #        which isn't very change resistant -- if the view structure changes,
  #        these tests will need to be updated. If there's a more resilient way
  #        to verify things, we should use it.
  
  def setup_vars
    create_portal
    create_curnit
    @portal.reload
  end

  # Web UI tests
  def test_list
    setup_vars
    get :list, :pid => @portal.id
    do_list_asserts(@curnit)
  end
  
  def test_show
    setup_vars
    get :show, :pid => @portal.id, :id => @curnit.id
    assert_response :success
    # assert that the correct data is represented
    assert_tag({:tag => 'tr', :child => {:tag => 'td', :content => "#{@curnit.name}"},
                :after => {:tag => 'tr', :child => {:tag => 'td', :content => "#{@curnit.id}"}}, 
                :before => {:tag => 'tr', :child => {:tag => 'td', :content => "#{@curnit.url}"}}
              })
  end
  
  def test_create_get
    setup_vars
    get :create, :pid => @portal.id
    assert_response :success
    # TODO more asserts
  end
  
  def test_create_post
    setup_vars
    post :create, {:pid => @portal.id, :curnit => {:name => "Test curnit", :url => "http://rails.dev.concord.org/curnits/otrunk-curnit-external-diytest.jar"} }
    do_create_edit_asserts
  end
  
  def test_edit_get
    setup_vars
    get :edit, :pid => @portal.id, :id => @curnit.id
    assert_response :success
    # TODO more asserts
  end
  
  def test_edit_post
    setup_vars
    post :edit, {:pid => @portal.id, :id  => @curnit.id, :curnit => {:name => "new name", :url => "http://confluence.concord.org/download/attachments/10503/otrunk-curnit-external-diytest.jar" }}
    @curnit.reload
    assert_equal "new name", @curnit.name
    assert_equal "http://confluence.concord.org/download/attachments/10503/otrunk-curnit-external-diytest.jar", @curnit.url
    do_create_edit_asserts
  end
  
  # REST API tests
  def test_rest_list
    setup_vars
    @request.env['HTTP_ACCEPT'] = "application/xml"
    get :list, {:pid => @portal.id}
    # make sure we get a 200 response
    assert_response :success
    # make sure all the curnits are returned
    assert_tag(:tag => 'curnits', :children => {:count => @portal.curnits.count })
    #make sure that the curnit we created is correctly represented
    assert_tag(:tag => 'curnit', :child => {:tag => 'name', :content => @curnit.name, :after => {:tag => 'id', :content => "#{@curnit.id}"}, :before => {:tag => 'url', :content => @curnit.url}})
  end
    
  def test_rest_show
    setup_vars
    @request.env['HTTP_ACCEPT'] = "application/xml"
    get :show, {:pid => @portal.id, :id => @curnit.id}
    # make sure we get a 200 response
    assert_response :success
    #make sure that the curnit we created is correctly represented
    assert_tag(:tag => 'curnit', :child => {:tag => 'name', :content => @curnit.name, :after => {:tag => 'id', :content => "#{@curnit.id}"}, :before => {:tag => 'url', :content => @curnit.url}})
  end
  
  def test_rest_update
    setup_vars
    new_url = "http://confluence.concord.org/download/attachments/10503/otrunk-curnit-external-diytest.jar"
    new_name = "REST test curnit update"
    @request.env['HTTP_ACCEPT'] = "application/xml"
    @request.env['CONTENT_TYPE'] = "application/xml"
    @request.env["RAW_POST_DATA"] = "<curnit><id>#{@curnit.id}</id><portal-id>#{@portal.id}</portal-id><name>#{new_name}</name><url>#{new_url}</url></curnit>"
    put :show, {:pid => @portal.id, :id => @curnit.id}
    @curnit.reload
    # TODO more asserts
    assert_response 201
    assert_equal new_url, @curnit.url
    assert_equal new_name, @curnit.name
  end
  
  def test_rest_create
    setup_vars
    @request.env['HTTP_ACCEPT'] = "application/xml"
    @request.env['CONTENT_TYPE'] = "application/xml"
    @request.env["RAW_POST_DATA"] = "<curnit><portal-id>#{@portal.id}</portal-id><name>REST test curnit</name><url>http://rails.dev.concord.org/curnits/otrunk-curnit-external-diytest.jar</url></curnit>"
    post :list, {:pid => @portal.id}
    # TODO more asserts
    assert_response 201
  end
  
  private
  
  def create_portal
    @portal = Portal.create!(:name => "Test portal",
                      :title => "Test title",
                      :vendor => "Test Vendor",
                      :home_page_url => "http://www.concord.org",
                      :image_url => "http://teemss2diy.concord.org/images/butterfly64x64.png")
  end
  
  def create_curnit
    @curnit = Curnit.create!(:name => "Test curnit",
                             :url => "http://rails.dev.concord.org/curnits/otrunk-curnit-external-diytest.jar",
                             :portal_id => @portal.id)
  end
  
  def do_list_asserts(curnit)
    # expect a 200 OK response
    assert_response :success
    # assert that @curnit shows up in the list
    assert_tag({:tag => 'td',
                :content => curnit.name,
                :before => {:tag => 'td', :content => curnit.url},
                :after => {:tag => 'td', :content => "#{curnit.id}"}
              })
    # assert that the table shows all the curnits
    # 2 rows per curnit, plus one for the header row
    assert_tag({:tag => 'table', :children => {:count => (Curnit.count*2 + 1)}})
  end
  
  def do_create_edit_asserts(curnit = nil)
    assert flash[:notice] =~ /Curnit ([0-9]+) was successfully [a-zA-Z]+./, "Invalid flash message found: #{flash[:notice]}"
    assert_redirected_to({:action => 'list'})
    if ! curnit
      curnit = Curnit.find(Regexp.last_match(1))
    end
    assert_valid curnit
    get :list, :pid => curnit.portal_id
    do_list_asserts(curnit)
  end
  
end
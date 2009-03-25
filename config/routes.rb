ActionController::Routing::Routes.draw do |map|
  map.resources :blobs
  map.raw_blob "blobs/:id/raw/:token", :controller => "blobs", :action => "raw"

  map.resources :notification_types

  map.resources :notification_listeners

  map.resources :users

  map.resource :sessions
  
  map.signup  '/signup', :controller => 'users',   :action => 'new' 
  map.login   '/login',  :controller => 'sessions', :action => 'new'
  map.logout  '/logout', :controller => 'sessions', :action => 'destroy'
  map.sessions_start  '/sessions/create', :controller => 'sessions', :action => 'create'
  map.activate '/activate/:activation_code', :controller => 'users', :action => 'activate', :activation_code => nil
  map.permission_denied '/permission_denied', :controller => 'sessions', :action => 'permission_denied'

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.

# offering: atom feed services

#  map.connect ':pid/offering/:id/atom', :controller => 'offering', :action => 'atom', :type => 'offering'

  map.resources :config_versions
  
# direct bundle manipulation

  map.resources :bundle_contents, :path_prefix => '/:pid', :member => { :ot_learner_data => :get }

  map.resources :bundles, :controller => 'bundle', :path_prefix => '/:pid', :member => { :ot_learner_data => :get }
  
  map.bundle ':pid/bundle/:id', :controller => 'bundle', :action => 'bundle'
  map.formatted_bundle ':pid/bundle/:id.:format', :controller => 'bundle', :action => 'bundle'
  map.bundle_copy ':pid/bundle/:id/copy/:wid', :controller => 'bundle', :action => 'copy'
  map.formatted_bundle_copy ':pid/bundle/:id/copy/:wid.:format', :controller => 'bundle', :action => 'copy'

# offering: java web start services
  # jnlp routes
  map.connect ':pid/offering/:id/jnlp/:wid', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => true, :nobundles => nil
  map.connect ':pid/offering/:id/jnlp/:wid/view', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => nil, :nobundles => nil
  map.connect ':pid/offering/:id/jnlp/user/:uid', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => true, :nobundles => nil
  map.connect ':pid/offering/:id/jnlp/user/:uid/view', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => nil, :nobundles => nil
  map.connect ':pid/offering/:id/jnlp/workgroup/:wid', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => true, :nobundles => nil
  # with nobundles
  map.connect ':pid/offering/:id/jnlp/:wid/nobundles', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => true, :nobundles => true
  map.connect ':pid/offering/:id/jnlp/:wid/view/nobundles', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => nil, :nobundles => true
  map.connect ':pid/offering/:id/jnlp/user/:uid/nobundles', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => true, :nobundles => true
  map.connect ':pid/offering/:id/jnlp/user/:uid/view/nobundles', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => nil, :nobundles => true
  map.connect ':pid/offering/:id/jnlp/workgroup/:wid/nobundles', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => true, :nobundles => true
  
  # config routes
  map.connect ':pid/offering/:id/config/:wid/:version', :controller => 'offering', :action => 'config', :savedata => true, :nobundles => nil
  map.connect ':pid/offering/:id/config/:wid/:version/view', :controller => 'offering', :action => 'config', :savedata => nil, :nobundles => nil
  map.connect ':pid/offering/:id/config/:wid/:version/nobundles', :controller => 'offering', :action => 'config', :savedata => true, :nobundles => true
  map.connect ':pid/offering/:id/config/:wid/:version/view/nobundles', :controller => 'offering', :action => 'config', :savedata => nil, :nobundles => true
  
  #bundle routes
  map.connect ':pid/offering/:id/bundle/:wid/:version', :controller => 'offering', :action => 'bundle', :nobundles => nil
  map.connect ':pid/offering/:id/bundle/:wid/:version/nobundles', :controller => 'offering', :action => 'bundle', :nobundles => true
#  map.connect ':pid/offering/:id/pod/:uuid', :controller => 'offering', :action => 'pod'

  map.connect ':pid/offering/:id/errorbundle_create', :controller => 'offering', :action => 'errorbundle_create'
  map.connect ':pid/offering/:id/errorbundle/:ebid', :controller => 'offering', :action => 'errorbundle', :ebid => 'ebid'

  # map.connect ':pid/offering/:id/logs/:wid/:lid/edit', :controller => 'log_bundles', :action => 'edit'
  map.connect ':pid/offering/:id/logs/:wid/:lid', :controller => 'log_bundles', :action => 'show'
  map.connect ':pid/offering/:id/logs/:wid', :controller => 'log_bundles', :action => 'index'
  map.connect ':pid/offering/:id/logs/:wid/new', :controller => 'log_bundles', :action => 'new'
  
#  map.connect ':pid/offering/:id/atom', :controller => 'offering', :action => 'jnlp', :type => 'workgroup'
#  map.connect ':pid/offering/:id/atom/:wid', :controller => 'offering', :action => 'jnlp', :type => 'workgroup'
#  map.connect ':pid/offering/:id/atom/:wid/:version', :controller => 'offering', :action => 'jnlp', :type => 'workgroup'

# offering: administrative

  map.connect ':pid/offering', :controller => 'offering', :action => 'list'
  map.connect ':pid/offering/list', :controller => 'offering', :action => 'list'
  map.connect ':pid/offering/create', :controller => 'offering', :action => 'create'
  map.connect ':pid/offering/edit/:id', :controller => 'offering', :action => 'edit'
#  map.connect ':pid/offering/destroy/:id', :controller => 'offering', :action => 'destroy'
  map.connect ':pid/offering/:id', :controller => 'offering', :action => 'show'
  map.connect ':pid/offering/:id/attribute', :controller => 'offering', :action => 'add_attribute'
  map.connect ':pid/offering/:id/attribute/:aid/edit', :controller => 'offering', :action => 'edit_attribute'
  map.connect ':pid/offering/:id/attribute/:aid/remove', :controller => 'offering', :action => 'remove_attribute'  
  map.connect ':pid/offering/:id/report_xls', :controller => 'offering', :action => 'report_xls'
  map.connect ':pid/offering/:id/curnitmap', :controller => 'offering', :action => 'curnitmap'
  map.connect ':pid/offering/:oid/workgroups', :controller => 'workgroup', :action => 'list_by_offering'
  map.connect ':pid/offering/:oid/workgroup/create', :controller => 'workgroup', :action => 'create'

# workgroup

  map.connect ':pid/workgroup', :controller => 'workgroup', :action => 'list'
  map.connect ':pid/workgroup/list', :controller => 'workgroup', :action => 'list'
  map.connect ':pid/workgroup/create', :controller => 'workgroup', :action => 'create'
  map.connect ':pid/workgroup/edit/:id', :controller => 'workgroup', :action => 'edit'
  map.connect ':pid/workgroup/report/:id', :controller => 'workgroup', :action => 'report'
  map.connect ':pid/workgroup/report/:id/xls', :controller => 'workgroup', :action => 'report_xls'
  map.connect ':pid/workgroup/report/:id/html', :controller => 'workgroup', :action => 'report_html'
#  map.connect ':pid/workgroup/destroy/:id', :controller => 'workgroup', :action => 'destroy'
  map.connect ':pid/workgroup/:id/membership/:version', :controller => 'workgroup', :action => 'membership'
  map.connect ':pid/workgroup/:id/membership', :controller => 'workgroup', :action => 'membership'
  map.connect ':pid/workgroup/:id/copy_bundle/:wid', :controller => 'workgroup', :action => 'copy_bundle'
#  map.connect ':pid/workgroup/atom', :controller => 'workgroup', :action => 'atom'
  map.connect ':pid/workgroup/:id', :controller => 'workgroup', :action => 'show'

  map.resources :workgroups, :controller => 'workgroup', :path_prefix => '/:pid', :member => { :ot_learner_data => :get }
  map.resources :workgroups, :controller => 'workgroup', :path_prefix => '/:pid', :member => { :bundles => :get }

# sail_user

  map.connect ':pid/sail_user', :controller => 'sail_user', :action => 'list'
  map.connect ':pid/sail_user/list', :controller => 'sail_user', :action => 'list'
  map.connect ':pid/sail_user/create', :controller => 'sail_user', :action => 'create'
  map.connect ':pid/sail_user/edit/:id', :controller => 'sail_user', :action => 'edit'
#  map.connect ':pid/sail_user/destroy/:id', :controller => 'sail_user', :action => 'destroy'
  map.connect ':pid/sail_user/:id', :controller => 'sail_user', :action => 'show'
  map.connect ':pid/sail_user/:id/workgroups', :controller => 'sail_user', :action => 'workgroups'

# jnlp

  map.connect ':pid/jnlp/', :controller => 'jnlp', :action => 'list'
  map.connect ':pid/jnlp/list', :controller => 'jnlp', :action => 'list'
  map.connect ':pid/jnlp/index', :controller => 'jnlp', :action => 'list'
  map.connect ':pid/jnlp/create', :controller => 'jnlp', :action => 'create'
  map.connect ':pid/jnlp/edit/:id', :controller => 'jnlp', :action => 'edit'
#  map.connect ':pid/jnlp/destroy/:id', :controller => 'jnlp', :action => 'destroy'
  map.connect ':pid/jnlp/:id', :controller => 'jnlp', :action => 'show'

# curnit

  map.connect ':pid/curnit/', :controller => 'curnit', :action => 'list'
#  map.connect ':pid/curnit/:id/jnlp/:jid', :controller => 'curnit', :action => 'jnlp'
  map.connect ':pid/curnit/list', :controller => 'curnit', :action => 'list'
  map.connect ':pid/curnit/create', :controller => 'curnit', :action => 'create'
  map.connect ':pid/curnit/edit/:id', :controller => 'curnit', :action => 'edit'
#  map.connect ':pid/curnit/destroy/:id', :controller => 'curnit', :action => 'destroy'
  map.connect ':pid/curnit/:id', :controller => 'curnit', :action => 'show'

# portal

  map.connect 'portal', :controller => 'portal', :action => 'list'
  map.connect 'portal/list', :controller => 'portal', :action => 'list'
  map.connect 'portal/create', :controller => 'portal', :action => 'create'
  map.connect 'portal/edit/:id', :controller => 'portal', :action => 'edit'
#  map.connect 'portal/destroy/:id', :controller => 'portal', :action => 'destroy'
   map.connect 'portal/:id', :controller => 'portal', :action => 'show'

  # Install the default route as the lowest priority.
#  map.connect ':controller/:action/:id'

#  map.connect 'users/:action', :controller => 'users'

  map.home '', :controller => "home", :action => 'index', :pid => nil
  map.connect ':pid', :controller => "home", :action => 'index'
  map.connect ':pid.:format', :controller => "home", :action => 'index'  

end

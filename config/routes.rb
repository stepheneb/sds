ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"

  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect 'offering/config/:pid/:oid/:uid', :controller => 'offering', :action => 'config'
  map.connect 'offering/jnlp/:pid/:oid/:uid', :controller => 'offering', :action => 'jnlp'
  map.connect 'offering/bundle/:pid/:oid/:uid/:bid', :controller => 'offering', :action => 'bundle'
  map.connect 'offering/bundle/:pid/:oid/:uid', :controller => 'offering', :action => 'bundle'
  map.connect 'offering/bundle/:pid/:id', :controller => 'offering', :action => 'bundle'
  map.connect 'offering/edit/:pid/:id', :controller => 'offering', :action => 'edit'
  map.connect 'offering/show/:pid/:id', :controller => 'offering', :action => 'show'
  map.connect 'offering/destroy/:pid/:id', :controller => 'offering', :action => 'destroy'
  map.connect 'offering/:pid/:oid/:uid/:bid', :controller => 'offering', :action => 'bundle'
  map.connect 'offering/:pid/:oid/:uid', :controller => 'offering', :action => 'bundle'

  map.connect 'jnlp/create/:pid', :controller => 'jnlp', :action => 'create'
  map.connect 'jnlp/new/:pid', :controller => 'jnlp', :action => 'new'
  map.connect 'jnlp/list/:pid', :controller => 'jnlp', :action => 'list'
  map.connect 'jnlp/:pid/:id', :controller => 'jnlp', :action => 'show'
  map.connect 'jnlp/:pid', :controller => 'jnlp', :action => 'list'

  map.connect 'curnit/create/:pid', :controller => 'curnit', :action => 'create'
  map.connect 'curnit/new/:pid', :controller => 'curnit', :action => 'new'
  map.connect 'curnit/list/:pid', :controller => 'curnit', :action => 'list'
  map.connect 'curnit/:pid/:id', :controller => 'curnit', :action => 'show'
  map.connect 'curnit/:pid', :controller => 'curnit', :action => 'list'

  map.connect 'portal/:id', :controller => 'portal', :action => 'show'
  map.connect 'portal', :controller => 'portal', :action => 'list'

  # Install the default route as the lowest priority.
  map.connect ':controller/:action/:id'
end

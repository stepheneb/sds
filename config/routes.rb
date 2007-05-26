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

# offering: atom feed services

#  map.connect ':pid/offering/:id/atom', :controller => 'offering', :action => 'atom', :type => 'offering'

# direct bundle manipulation

  map.connect ':pid/bundle/:id', :controller => 'bundle', :action => 'bundle'

# offering: java web start services

  map.connect ':pid/offering/:id/jnlp/:wid', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => true
  map.connect ':pid/offering/:id/jnlp/:wid/view', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => nil
  map.connect ':pid/offering/:id/jnlp/user/:uid', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => true
  map.connect ':pid/offering/:id/jnlp/user/:uid/view', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => nil
  map.connect ':pid/offering/:id/jnlp/workgroup/:wid', :controller => 'offering', :action => 'jnlp', :type => 'workgroup', :savedata => true
  map.connect ':pid/offering/:id/jnlp/user/:uid/view', :controller => 'offering', :action => 'jnlp', :type => 'user', :savedata => nil
  map.connect ':pid/offering/:id/config/:wid/:version', :controller => 'offering', :action => 'config', :savedata => true
  map.connect ':pid/offering/:id/config/:wid/:version/view', :controller => 'offering', :action => 'config', :savedata => nil
  map.connect ':pid/offering/:id/bundle/:wid/:version', :controller => 'offering', :action => 'bundle'
#  map.connect ':pid/offering/:id/pod/:uuid', :controller => 'offering', :action => 'pod'

  map.connect ':pid/offering/:id/errorbundle_create', :controller => 'offering', :action => 'errorbundle_create'
  map.connect ':pid/offering/:id/errorbundle/:ebid', :controller => 'offering', :action => 'errorbundle', :ebid => 'ebid'

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
  map.connect ':pid/offering/:oid/workgroups', :controller => 'workgroup', :action => 'list_by_offering'

# workgroup

  map.connect ':pid/workgroup', :controller => 'workgroup', :action => 'list'
  map.connect ':pid/workgroup/list', :controller => 'workgroup', :action => 'list'
  map.connect ':pid/workgroup/create', :controller => 'workgroup', :action => 'create'
  map.connect ':pid/workgroup/edit/:id', :controller => 'workgroup', :action => 'edit'
  map.connect ':pid/workgroup/report/:id', :controller => 'workgroup', :action => 'report'
  map.connect ':pid/workgroup/report_csv/:id', :controller => 'workgroup', :action => 'report_csv'
  map.connect ':pid/workgroup/report/:id/xls', :controller => 'workgroup', :action => 'report_xls'
#  map.connect ':pid/workgroup/destroy/:id', :controller => 'workgroup', :action => 'destroy'
  map.connect ':pid/workgroup/:id/membership/:version', :controller => 'workgroup', :action => 'membership'
  map.connect ':pid/workgroup/:id/membership', :controller => 'workgroup', :action => 'membership'
#  map.connect ':pid/workgroup/atom', :controller => 'workgroup', :action => 'atom'
   map.connect ':pid/workgroup/:id', :controller => 'workgroup', :action => 'show'

# sail_user

  map.connect ':pid/sail_user', :controller => 'sail_user', :action => 'list'
  map.connect ':pid/sail_user/list', :controller => 'sail_user', :action => 'list'
  map.connect ':pid/sail_user/create', :controller => 'sail_user', :action => 'create'
  map.connect ':pid/sail_user/edit/:id', :controller => 'sail_user', :action => 'edit'
#  map.connect ':pid/sail_user/destroy/:id', :controller => 'sail_user', :action => 'destroy'
  map.connect ':pid/sail_user/:id', :controller => 'sail_user', :action => 'show'

# user

  map.connect ':pid/user', :controller => 'user', :action => 'list'
  map.connect ':pid/user/list', :controller => 'user', :action => 'list'
  map.connect ':pid/user/create', :controller => 'user', :action => 'create'
  map.connect ':pid/user/edit/:id', :controller => 'user', :action => 'edit'
#  map.connect ':pid/user/destroy/:id', :controller => 'user', :action => 'destroy'
  map.connect ':pid/user/:id', :controller => 'user', :action => 'show'

# jnlp

  map.connect ':pid/jnlp/', :controller => 'jnlp', :action => 'list'
  map.connect ':pid/jnlp/list', :controller => 'jnlp', :action => 'list'
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

  map.connect 'user/:action', :controller => 'user'
  
  map.connect ':pid', :controller => 'home', :action => 'index'
  
  map.connect '', :controller => "home", :action => 'index', :pid => nil

end

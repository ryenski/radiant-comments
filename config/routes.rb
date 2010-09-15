ActionController::Routing::Routes.draw do |map|
  map.namespace :admin do |admin|
    admin.connect 'comments/:status', :controller => 'comments', :status => 'unapproved', :conditions => { :method => :get }, :requirements => { :status => /all|unapproved|approved/ }
    admin.connect 'comments/:status.:format', :controller => 'comments', :status => /all|approved|unapproved/, :conditions => { :method => :get }
    admin.resources :comments, :member => { :remove => :get, :approve => :put, :unapprove => :put }, :collection => {:destroy_unapproved => :delete}
    admin.page_enable_comments '/pages/:page_id/comments/enable', :controller => 'comments', :action => 'enable', :conditions => {:method => :put}
  end
  map.with_options(:controller => 'admin/comments') do |comments|
    comments.connect 'admin/pages/:page_id/comments/:status', :status => /all|approved|unapproved/, :conditions => { :method => :get }
    comments.connect 'admin/pages/:page_id/comments/:status.:format', :status => /all|approved|unapproved/, :conditions => { :method => :get }
    comments.admin_page_comments 'admin/pages/:page_id/comments/:action'
    comments.admin_page_comment 'admin/pages/:page_id/comments/:id/:action'
  end
  # This needs to be last, otherwise it hoses the admin routes.
  map.resources :comments, :name_prefix => "page_", :path_prefix => "*url", :controller => "comments"
end
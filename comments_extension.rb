#require 'page_extender'
require_dependency 'application'

class CommentsExtension < Radiant::Extension
  version "0.0.3"
  description "Adds blog-like comments and comment functionality to pages."
  url "http://svn.artofmission.com/svn/plugins/radiant/extensions/comments/"
  
  define_routes do |map|
    map.resources :comments, :path_prefix => "/pages/:page_id", :controller => "comments" # Regular routes for comments
    map.with_options(:controller => 'admin/comments') do |comments| 
      comments.resources :comments, :path_prefix => "/admin", :name_prefix => "admin_", :member => {:approve => :get, :unapprove => :get} # Admin routes for comments
      comments.admin_page_comments 'admin/pages/:page_id/comments/:action'  # This route allows us to nicely pull up comments for a particular page
      comments.admin_page_comment 'admin/pages/:page_id/comments/:id/:action' # This route pulls up a particular comment for a particular page
    end
  end
  
  def activate
    Page.send :include, CommentTags
    Comment
    
    Page.class_eval do
      has_many :comments, :dependent => :destroy
      has_many :approved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NOT NULL"
      has_many :unapproved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NULL"
    end
    
    if admin.respond_to? :page
      admin.page.edit.add :parts_bottom, "edit_comments_enabled", :before => "edit_timestamp"
      admin.page.index.add :sitemap_head, "index_head_view_comments"
      admin.page.index.add :node, "index_view_comments"
    end
    
    admin.tabs.add "Comments", "/admin/comments?status=unapproved", :visibility => [:all]

    { 'notification' => 'false',
      'notification_from' => '',
      'notification_to' => '',
      'akismet_key' => '',
      'akismet_url' => '',
    }.each{|k,v| Radiant::Config.create(:key => "comments.#{k}", :value => v) unless Radiant::Config["comments.#{k}"]}
  end
  
  def deactivate
  end
  
end
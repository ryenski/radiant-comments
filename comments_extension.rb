require_dependency 'application'

class CommentsExtension < Radiant::Extension
  version "0.0.5"
  description "Adds blog-like comments and comment functionality to pages."
  url "http://github.com/ntalbott/radiant-comments/tree/master"
  
  define_routes do |map|                
    map.with_options(:controller => 'admin/comments') do |comments| 
      comments.connect 'admin/comments/:status', :status => /all|approved|unapproved/, :conditions => { :method => :get }
      comments.connect 'admin/comments/:status.:format'
      comments.connect 'admin/pages/:page_id/comments/:status.:format'
      comments.connect 'admin/pages/:page_id/comments/all.:format'
      
      comments.resources :comments, :path_prefix => "/admin", :name_prefix => "admin_", :member => {:approve => :get, :unapprove => :get}
      comments.admin_page_comments 'admin/pages/:page_id/comments/:action'
      comments.admin_page_comment 'admin/pages/:page_id/comments/:id/:action'
    end
    # This needs to be last, otherwise it hoses the admin routes.
    map.resources :comments, :name_prefix => "page_", :path_prefix => "*url", :controller => "comments"
  end
  
  def activate
    Page.send :include, CommentTags
    Comment
    
    Page.class_eval do
      has_many :comments, :dependent => :destroy, :order => "created_at ASC"
      has_many :approved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NOT NULL", :order => "created_at ASC"
      has_many :unapproved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NULL", :order => "created_at ASC"
      attr_accessor :last_comment
      attr_accessor :selected_comment
      
      def has_visible_comments?
        !(approved_comments.empty? && selected_comment.nil?)
      end
    end
    
    if admin.respond_to? :page
      admin.page.edit.add :parts_bottom, "edit_comments_enabled", :before => "edit_timestamp"
      admin.page.index.add :sitemap_head, "index_head_view_comments"
      admin.page.index.add :node, "index_view_comments"
    end
    
    admin.tabs.add "Comments", "/admin/comments/unapproved", :visibility => [:all]

    { 'notification' => 'false',
      'notification_from' => '',
      'notification_to' => '',
      'notification_site_name' => '',
      'notify_creator' => 'true',
      'notify_updater' => 'false',
      'akismet_key' => '',
      'akismet_url' => '',
      'filters_enabled' => 'true',
    }.each{|k,v| Radiant::Config.create(:key => "comments.#{k}", :value => v) unless Radiant::Config["comments.#{k}"]}
    
    require "fastercsv"
    
    ActiveRecord::Base.class_eval do
      def self.to_csv(*args)
        find(:all).to_csv(*args)
      end

      def export_columns(format = nil)
        self.class.content_columns.map(&:name) - ['created_at', 'updated_at']
      end

      def to_row(format = nil)
        export_columns(format).map { |c| self.send(c) }
      end
    end
    
    Array.class_eval do
      def to_csv(options = {})
        return "" if first.nil?
        if all? { |e| e.respond_to?(:to_row) }
          header_row = first.export_columns(options[:format]).to_csv
          content_rows = map { |e| e.to_row(options[:format]) }.map(&:to_csv)
          ([header_row] + content_rows).join
        else
          FasterCSV.generate_line(self, options)
        end
      end
    end    
  end
  
  def deactivate
  end
  
end

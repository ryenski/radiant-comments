class CommentsExtension < Radiant::Extension
  version "0.1"
  description "Adds blog-like comments and comment functionality to pages."
  url "http://github.com/saturnflyer/radiant-comments"

  define_routes do |map|
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

  def activate
    require 'sanitize'
    
    Dir["#{File.dirname(__FILE__)}/app/models/*_filter.rb"].each do |file|
      require file
    end

    Page.class_eval do
      include CommentPageExtensions
      include CommentTags
    end

    if admin.respond_to? :page
      admin.page.edit.add :parts_bottom, "edit_comments_enabled", :before => "edit_timestamp"
      admin.page.index.add :sitemap_head, "index_head_view_comments"
      admin.page.index.add :node, "index_view_comments"
    end

    admin.tabs.add "Comments", "/admin/comments", :visibility => [:all]
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

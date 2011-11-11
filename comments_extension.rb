require "mollom"
require "sanitize"
require File.expand_path("../lib/radiant-comments-extension/version", __FILE__)
class CommentsExtension < Radiant::Extension
  version RadiantCommentsExtension::VERSION
  description "Adds blog-like comments and comment functionality to pages."
  url "http://github.com/saturnflyer/radiant-comments"

  def activate
    Dir["#{File.dirname(__FILE__)}/app/models/*_filter.rb"].each do |file|
      require file
    end

    Page.class_eval do
      include CommentPageExtensions
      include CommentTags
    end

    if admin.respond_to? :page
      admin.page.edit.add :extended_metadata, "edit_comments_enabled"
    end

    tab "Content" do
    	add_item("Comments", "/admin/comments")
    end.

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

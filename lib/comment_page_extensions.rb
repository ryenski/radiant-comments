module CommentPageExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :process, :comments

      has_many :comments, :dependent => :destroy, :order => "created_at ASC"
      has_many :approved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NOT NULL", :order => "created_at ASC"
      has_many :unapproved_comments, :class_name => "Comment", :conditions => "comments.approved_at IS NULL", :order => "created_at ASC"
      attr_accessor :last_comment
      attr_accessor :selected_comment
    end
  end

  def has_visible_comments?
    !(approved_comments.empty? && selected_comment.nil?)
  end

  def process_with_comments(request, response)
    if Radiant::Config['comments.post_to_page?'] && request.post? && request.parameters[:comment]
      begin
        comment = self.comments.build(request.parameters[:comment])
        comment.request = self.request = request
        comment.save!
        
        # Purge the cache
        Radiant::Cache.clear
        if Radiant::Config['comments.notification'] == "true"
          if comment.approved? || Radiant::Config['comments.notify_unapproved'] == "true"
            CommentMailer.deliver_comment_notification(comment)
          end
        end
        absolute_url = "#{request.protocol}#{request.host_with_port}#{relative_url_for(url, request)}#comment-#{comment.id}"
        response.redirect(absolute_url, 303)
        return
      rescue ActiveRecord::RecordInvalid
        self.last_comment = comment
      end
    end
    process_without_comments(request, response)
  end
end
module CommentPageExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :process, :comments

      has_many :comments, :dependent => :delete_all, :order => "created_at ASC"
      attr_accessor :last_comment
      attr_accessor :selected_comment
    end
  end

  def has_visible_comments?
    !(comments.approved.empty? && selected_comment.nil?)
  end

  def process_with_comments(request, response)
    if Radiant::Config['comments.post_to_page?'] && request.post? && request.parameters[:comment]
      begin
        comment = self.comments.build(request.parameters[:comment])
        comment.request = self.request = request
        comment.save!

        if Radiant::Config['comments.notification'] == "true"
          if comment.approved? || Radiant::Config['comments.notify_unapproved'] == "true"
            CommentMailer.deliver_comment_notification(comment)
          end
        end
        if comment.approved?
          absolute_url = "#{request.protocol}#{request.host_with_port}#{relative_url_for(url, request)}#comment-#{comment.id}"
          response.redirect(absolute_url, 303)
          return
        else
          self.selected_comment = comment
        end
      rescue ActiveRecord::RecordInvalid
        self.last_comment = comment
      end
    end
    process_without_comments(request, response)
  end
end
module CommentPageExtensions
  def self.included(base)
    base.class_eval do
      alias_method_chain :process, :comments

      has_many :comments, :dependent => :delete_all, :order => "created_at ASC"
      attr_accessor :last_comment
      attr_accessor :selected_comment
      attr_accessor :captcha_url
      attr_accessor :comment_mollom_id
      attr_accessor :posted_comment_is_spam
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
        elsif Comment.spam_filter == MollomSpamFilter && MollomSpamFilter.mollom_response(comment).to_s == 'unsure'
          self.last_comment = comment
          captcha = MollomSpamFilter.mollom.image_captcha
          comment.update_attribute(:mollom_id, captcha['session_id']) # because mollom does not guarantee the session_id will be kept when you pass one to mollom.image_captcha
          self.captcha_url = captcha['url']
          self.comment_mollom_id = captcha['session_id']
        end
      rescue Mollom::NoAvailableServers
        logger.error "*** Mollom was unavailable (Mollom::NoAvailableServers)"
      rescue ActiveRecord::RecordInvalid
        self.last_comment = comment
      rescue SpamFilter::Spam
        self.posted_comment_is_spam = true
        comment.destroy
      end
    end
    process_without_comments(request, response)
  end
  
end
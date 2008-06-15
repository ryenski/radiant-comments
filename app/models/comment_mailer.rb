class CommentMailer < ActionMailer::Base
  def comment_notification(comment, sent_at = Time.now)
    page_url  = homepage_url(:host => default_url_options[:host], :port => default_url_options[:port])[0..-2] + comment.page.url
    site_name = Radiant::Config['comments.notification_site_name']
    
    subject    "[#{site_name}] New comment posted"
    recipients Radiant::Config['comments.notification_to']
    from       Radiant::Config['comments.notification_from']
    sent_on    sent_at
    
    body :site_name => site_name, :comment => comment, :page_url => page_url
  end
end

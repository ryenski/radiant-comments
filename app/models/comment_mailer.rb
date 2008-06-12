class CommentMailer < ActionMailer::Base
  
  def comment_notification(url, sent_at = Time.now)
    site_name   = Radiant::Config['comments.notification_site_name']
    @subject    = "New comment posted requires approval"
    @body       = {@name = site_name, @url = url}
    @recipients = Radiant::Config['comments.notification_to']
    @from       = Radiant::Config['comments.notification_from']
    @sent_on    = sent_at
  end
end
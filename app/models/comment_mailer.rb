class CommentMailer < ActionMailer::Base
  
  def comment_notification(sent_at = Time.now)
    @subject    = "[ AS Website ] New comment posted requires approval"
    @body       = {}
    @recipients = "admin@example.com"
    @from       = "admin@example.com"
    @sent_on    = sent_at
  end
end
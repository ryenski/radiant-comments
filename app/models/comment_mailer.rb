class CommentMailer < ActionMailer::Base
  def comment_notification(comment, sent_at = Time.now)
    notify_creator_config = Radiant::Config['comments.notify_creator']
    notify_updater_config = Radiant::Config['comments.notify_updater']
    notification_to_config = Radiant::Config['comments.notification_to']
    
    receivers = []
    receivers << notification_to_config unless notification_to_config.blank?
    receivers << comment.page.created_by.email unless notify_creator_config == "false"
    if notify_updater_config == "true" && comment.page.updated_by != comment.page.created_by
      receivers << comment.page.updated_by.email
    end
    
    page_url  = root_url(:host => default_url_options[:host], :port => default_url_options[:port])[0..-2] + comment.page.url
    site_name = Radiant::Config['comments.notification_site_name']
    
    subject    "[#{site_name}] New #{comment.ap_status} comment posted"
    recipients receivers.join(',')
    from       Radiant::Config['comments.notification_from']
    sent_on    sent_at
    
    body :site_name => site_name, :comment => comment, :page_url => page_url
  end
end

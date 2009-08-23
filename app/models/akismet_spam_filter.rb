class AkismetSpamFilter < SpamFilter
  def message
    'Protected by <a href="http://akismet.com/">Akismet</a>'
  end
  
  def configured?
    !Radiant::Config['comments.akismet_key'].blank? &&
    !Radiant::Config['comments.akismet_url'].blank?
  end

  def approved?(comment)
    (akismet.valid? && ham?(comment)) || raise(SpamFilter::Spam)
  rescue
    # Spam and anything raised by Net::HTTP, e.g. Errno, Timeout stuff
    false
  end

  def akismet
    @akismet ||= Akismet.new(Radiant::Config['comments.akismet_key'], Radiant::Config['comments.akismet_url'])
  end

  private
  def ham?(comment)
    !akismet.commentCheck(
      comment.author_ip,            # remote IP
      comment.user_agent,           # user agent
      comment.referrer,             # http referer
      comment.page.url,             # permalink
      'comment',                    # comment type
      comment.author,               # author name
      comment.author_email,         # author email
      comment.author_url,           # author url
      comment.content,              # comment text
      {}                            # other
    )
  end
end
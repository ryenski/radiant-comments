class AkismetSpamFilter < SpamFilter
  def configured?
    !Radiant::Config['comments.akismet_key'].blank? &&
    !Radiant::Config['comments.akismet_url'].blank?
  end

  def approved?(comment)
    (akismet.valid? && ham?(comment)) || raise(SpamFilter::Spam)
  rescue
    # Spam and anything raised by Net::HTTP, e.g. Errno stuff
    comment.errors.add_to_base("Failed spam check.")
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
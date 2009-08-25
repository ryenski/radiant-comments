# A simple challenge-response spam filter
class SimpleSpamFilter < SpamFilter
  def message
    if required?
      'Comments are protected from spam by a simple challenge/response field.  For more robust spam filtering, try <a href="http://mollom.com">Mollom</a> or <a href="http://akismet.com/">Akismet</a>.'
    else
      'You have 3 built-in options for spam protection although currently comments are not automatically protected. Install <a href="http://mollom.com">Mollom</a> or <a href="http://akismet.com/">Akismet</a> to protect against comment spam through an external service, or use the &lt;r:comments:spam_answer_tag /&gt;. Instructions may be found in the README.'
    end
  end
  
  def configured?
    true
  end

  # Instead of filtering at the approval stage, the simple spam filter requires 
  # the user to give the correct answer before saving the record.
  def valid?(comment)
    if !required? || comment.valid_spam_answer == hashed_spam_answer(comment)
      true
    else
      comment.errors.add :spam_answer, "is not correct."
      false
    end
  end
  
  def approved?(comment)
    true
  end

  def required?
    Radiant::Config['comments.simple_spam_filter_required?']
  end

  private
  def hashed_spam_answer(comment)
    Digest::MD5.hexdigest(comment.spam_answer.to_s.to_slug)
  end
end
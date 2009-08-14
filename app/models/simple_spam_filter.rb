# A simple challenge-response spam filter
class SimpleSpamFilter < SpamFilter
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
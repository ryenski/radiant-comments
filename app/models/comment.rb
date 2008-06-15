class Comment < ActiveRecord::Base
  belongs_to :page, :counter_cache => true
  validates_presence_of :author, :author_email, :content
  
  before_save :auto_approve
  
  def self.per_page
    50
  end
  
  def request=(request)
    self.author_ip = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end
  
  def akismet
    @akismet ||= Akismet.new(Radiant::Config['comments.akismet_key'], Radiant::Config['comments.akismet_url'])
  end
  
  # If the Akismet details are valid, and Akismet thinks this is a non-spam
  # comment, this method will return true
  def auto_approve?
    if akismet.valid?
      # We do the negation because true means spam, false means ham
      !akismet.commentCheck(
        self.author_ip,            # remote IP
        self.user_agent,           # user agent
        self.referrer,             # http referer
        self.page.url,             # permalink
        'comment',                 # comment type
        self.author,               # author name
        self.author_email,         # author email
        self.author_url,           # author url
        self.content,              # comment text
        {}                         # other
      )
    else
      false
    end
  end
  
  def approved?
    return true if approved_at
    return false
  end
  
  def approve!
    self.update_attribute(:approved_at, Time.now)
  end
  
  def unapprove!
    self.update_attribute(:approved_at, nil)
  end
  
  private
  
    def auto_approve
      self.approved_at = Time.now if auto_approve?
    end
  
end

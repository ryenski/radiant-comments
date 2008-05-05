class Comment < ActiveRecord::Base
  belongs_to :page, :counter_cache => true
  validates_presence_of :author, :author_email, :content
  
  def self.per_page
    50
  end
  
  def request=(request)
    self.author_ip = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end
  
  # Akismet Spam Filter
  # Marks a content item as spam unless it checks out with Akismet
  def is_spam?  
    # You'll need to get your own Akismet API key from www.akismet.com
    @akismet = Akismet.new('123456789', 'http://yourblog.wordpress.com')
    return nil unless @akismet.verifyAPIKey
    
    return true if @akismet.commentCheck(
              self.author_ip,            # remote IP
              self.user_agent,           # user agent
              self.referrer,             # http referer
              self.page.url,             # permalink
              'comment',                 # comment type
              self.author,               # author name
              self.author_email,         # author email
              self.author_url,           # author url
              self.content,              # comment text
              {})                        # other
    return false
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
  
end

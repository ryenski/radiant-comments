class Comment < ActiveRecord::Base
  belongs_to :page, :counter_cache => true
  validates_presence_of :author, :author_email, :content
  
  before_save :auto_approve
  before_save :apply_filter
  
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
  
  def unapproved?
    !approved?
  end
  
  def approved?
    !approved_at.nil?
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
    
    def apply_filter
      self.content_html = filter.filter(content)
    end
    
    def filter
      filtering_enabled? && filter_from_form || SimpleFilter.new
    end
    
    def filter_from_form
      TextFilter.descendants.find { |f| f.filter_name = filter_id }
    end
    
    def filtering_enabled?
      Radiant::Config['comments.filters_enabled'] == "true"
    end
  
  class SimpleFilter
    include ERB::Util
    include ActionView::Helpers::TextHelper
    include ActionView::Helpers::TagHelper
    
    def filter(content)
      simple_format(h(content))
    end
  end
end

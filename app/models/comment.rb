class Comment < ActiveRecord::Base
  belongs_to :page, :counter_cache => true
  validates_presence_of :author, :author_email, :content
  
  before_save :auto_approve
  before_save :apply_filter
  after_save  :save_mollom_servers
    
  MOLLOM_SERVER_CACHE = RAILS_ROOT + '/tmp/mollom_servers.yaml'
    
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
  
  def save_mollom_servers
    if mollom.key_ok?
      File.open(MOLLOM_SERVER_CACHE,'w') do |f|
        f.write mollom.server_list.to_yaml
      end
    end
  rescue Mollom::Error
  end
  
  def mollom
    return @mollom if @mollom
    @mollom ||= Mollom.new(:private_key => Radiant::Config['comments.mollom_privatekey'], :public_key => Radiant::Config['comments.mollom_publickey'])
    if (File.exists?(MOLLOM_SERVER_CACHE))
      @mollom.server_list = YAML::load(File.read(MOLLOM_SERVER_CACHE))
    end    
    @mollom
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
      elsif mollom.key_ok?
        response = mollom.check_content(
          :author_name => self.author,            # author name     
          :author_mail => self.author_email,         # author email
          :author_url => self.author_url,           # author url
          :post_body => self.content              # comment text
          )
          ham = response.ham?
          self.mollom_id = response.session_id
       response.ham?  
    else
      false
    end
  rescue Mollom::Error
    return false
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
    # if we have to unapprove, and use mollom, it means
    # the initial check was false. Submit this to mollom as Spam.
    # Ideally, we'd need a different feedback for
    #  - spam
    #  - profanity
    #  - unwanted
    #  - low-quality
     begin
     if mollom.key_ok? and !self.mollom_id.empty?
        mollom.send_feedback :session_id => self.mollom_id, :feedback => 'spam'
      end
    rescue Mollom::Error => e
      raise Comment::AntispamWarning.new(e.to_s)
    end
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
      TextFilter.descendants.find { |f| f.filter_name == filter_id }
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
  
  class AntispamWarning < StandardError; end
end

require 'digest/md5'
class Comment < ActiveRecord::Base
  include ActionView::Helpers::SanitizeHelper
  extend ActionView::Helpers::SanitizeHelper::ClassMethods
  belongs_to :page, :counter_cache => true
  
  validate :validate_spam_answer
  validates_presence_of :author, :author_email, :content
  
  before_save :auto_approve
  before_save :apply_filter
  after_save  :save_mollom_servers
    
  attr_accessor :valid_spam_answer, :spam_answer
  attr_accessible :author, :author_email, :author_url, :filter_id, :content, :valid_spam_answer, :spam_answer
  
  def self.per_page
    count = Radiant::Config['comments.per_page'].to_i.abs
    count > 0 ? count : 50
  end
  
  def self.simple_spam_filter_enabled?
    Radiant::Config['comments.simple_spam_filter_required?']
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
    Rails.cache.write('MOLLOM_SERVER_CACHE', mollom.server_list.to_yaml) if mollom.key_ok?
  rescue Mollom::Error #TODO: something with this error...
  end
  
  def mollom
    return @mollom if @mollom
    @mollom ||= Mollom.new(:private_key => Radiant::Config['comments.mollom_privatekey'], :public_key => Radiant::Config['comments.mollom_publickey'])
    unless Rails.cache.read('MOLLOM_SERVER_CACHE').blank?
      @mollom.server_list = YAML::load(Rails.cache.read('MOLLOM_SERVER_CACHE'))
    end    
    @mollom
  end
  
  # If the Akismet details are valid, and Akismet thinks this is a non-spam
  # comment, this method will return true
  def auto_approve?
    return false if Radiant::Config['comments.auto_approve'] != "true"
    if simple_spam_filter_required?
      passes_logic_spam_filter?
    elsif akismet.valid?
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
  
  def ap_status
    if approved?
      "approved"
    else
      "unapproved"
    end
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
  
    def validate_spam_answer
      if simple_spam_filter_required? && !passes_logic_spam_filter?
        self.errors.add :spam_answer, "is not correct."
      end
    end
    
    def passes_logic_spam_filter?
      valid_spam_answer == hashed_spam_answer
    end
    
    def simple_spam_filter_required?
      !valid_spam_answer.blank? && Comment.simple_spam_filter_enabled?
    end
    
    def hashed_spam_answer
      Digest::MD5.hexdigest(spam_answer.to_s.to_slug)
    end

    def auto_approve
      self.approved_at = Time.now if auto_approve?
    end
    
    def apply_filter
      self.content_html = sanitize(filter.filter(content))
    end
    
    def filter
      if filtering_enabled? && filter_from_form
        filter_from_form
      else
        SimpleFilter.new
      end
    end
    
    def filter_from_form
      unless filter_id.blank?
        TextFilter.descendants.find { |f| f.filter_name == filter_id }
      else
        nil
      end
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

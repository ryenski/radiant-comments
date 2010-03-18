require 'digest/md5'
require 'sanitize' 
class Comment < ActiveRecord::Base
  belongs_to :page, :counter_cache => true

  named_scope :unapproved, :conditions => {:approved_at => nil}
  named_scope :approved, :conditions => 'approved_at IS NOT NULL'
  named_scope :recent, :order => 'created_at DESC'

  validate :check_for_spam
  validates_presence_of :author, :author_email, :content

  before_save :auto_approve
  before_save :apply_filter
  before_save :canonicalize_url

  attr_accessor :valid_spam_answer, :spam_answer
  attr_accessible :author, :author_email, :author_url, :filter_id, :content, :valid_spam_answer, :spam_answer

  def self.per_page
    count = Radiant::Config['comments.per_page'].to_i.abs
    count > 0 ? count : 50
  end

  def self.spam_filter
    @spam_filter ||= SpamFilter.select
  end

  def self.simple_spam_filter_enabled?
    spam_filter == SimpleSpamFilter && spam_filter.required?
  end
  
  def request=(request)
    self.author_ip = request.remote_ip
    self.user_agent = request.env['HTTP_USER_AGENT']
    self.referrer = request.env['HTTP_REFERER']
  end

  def is_ham?
    spam_filter.valid?(self)
  end

  def auto_approve?
    Radiant::Config['comments.auto_approve'] == "true" && is_ham?
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
    spam_filter.spam!(self)
  end

  def check_for_spam
    spam_filter && spam_filter.valid?(self)
  end

  private
    def spam_filter
      self.class.spam_filter
    end
    
    def auto_approve
      self.approved_at = Time.now if auto_approve?
      true
    end

    def apply_filter
      cleaner_type = defined?(COMMENT_SANITIZE_OPTION) ? COMMENT_SANITIZE_OPTION : Sanitize::Config::RELAXED
      sanitized_content = Sanitize.clean(content, cleaner_type)
      self.content_html = filter.filter(sanitized_content)
    end

    def canonicalize_url
      self.author_url = CGI.escapeHTML(author_url =~ /\Ahttps?:\/\//i ? author_url : "http://#{author_url}") unless author_url.blank?
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
      simple_format(escape_once(content))
    end
  end

  class AntispamWarning < StandardError; end
end

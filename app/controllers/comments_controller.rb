class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token
  before_filter :find_page
  before_filter :set_host

  def index
    @page.selected_comment = @page.comments.find_by_id(flash[:selected_comment])
    @page.request = request
    render :text => @page.render
  end
  
  def create
    comment = @page.comments.build(params[:comment])
    comment.request = request
    comment.request = @page.request = request
    comment.save!
    
    clear_single_page_cache(comment)
    if Radiant::Config['comments.notification'] == "true"
      if comment.approved? || Radiant::Config['comments.notify_unapproved'] == "true"
        CommentMailer.deliver_comment_notification(comment)
      end
    end
    
    if comment.approved?
      redirect_to "#{@page.url}comments#comment-#{comment.id}"
    elsif Comment.spam_filter == MollomSpamFilter && MollomSpamFilter.mollom_response(comment).to_s == 'unsure'
      set_up_page_with_captcha(comment)
      render :text => @page.render and return
    else
      @page.posted_comment_is_spam = true
      #comment.destroy
      render :text => @page.render
    end
  rescue ActiveRecord::RecordInvalid
    if comment.errors.on(:spam_answer)
      @page.posted_comment_is_spam = true
    end
    @page.last_comment = comment
    render :text => @page.render
  rescue SpamFilter::Spam
    @page.posted_comment_is_spam = true
    #comment.destroy
    render :text => @page.render
  end

  def solve_captcha
    comment = Comment.find_by_mollom_id(params[:comment_mollom_id])
    answer = params[:captcha_answer]
    mollom = Comment.spam_filter.mollom
    if mollom.valid_captcha? :session_id => comment.mollom_id, :solution => answer
      comment.approve!
      redirect_to "#{@page.url}comments#comment-#{comment.id}"
    else
      set_up_page_with_captcha(comment)
      render :text => @page.render
    end
  rescue Mollom::Error # when you don't provide 'correct' or 'incorrect' in mollom developer mode
    set_up_page_with_captcha(comment)
    render :text => @page.render
  end
  
  private
  
    def find_page
      url = params[:url]
      url.shift if defined?(SiteLanguage) && SiteLanguage.count > 1
      @page = Page.find_by_url(url.join("/"))
    end
    
    def set_host
      CommentMailer.default_url_options[:host] = request.host_with_port
    end
    
    def clear_single_page_cache(comment)
      if comment && comment.page
        unless defined?(ResponseCache)
          Radiant::Cache::EntityStore.new.purge(comment.page.url)
          Radiant::Cache::MetaStore.new.purge(comment.page.url)
        else
          ResponseCache.instance.clear
        end
      end
    end

    def set_up_page_with_captcha(comment)
      mollom = Comment.spam_filter.mollom
      if comment.mollom_id.nil?
        captcha = mollom.image_captcha
        comment.update_attribute(:mollom_id, captcha['session_id'])
      else
        captcha = mollom.image_captcha(:session_id => comment.mollom_id)
      end
      @page.last_comment = comment
      @page.captcha_url = captcha['url']
      @page.comment_mollom_id = @page.captcha_url[/\/([a-z0-9]*).png/, 1]
    end
  
end

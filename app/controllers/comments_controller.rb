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
    
    flash[:selected_comment] = comment.id
    redirect_to "#{@page.url}comments#comment-#{comment.id}"
  rescue ActiveRecord::RecordInvalid
    @page.last_comment = comment
    render :text => @page.render
 # rescue Comments::MollomUnsure
    #flash, en render :text => @page.render
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
  
end

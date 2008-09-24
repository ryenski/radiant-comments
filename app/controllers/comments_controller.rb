class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token
  before_filter :find_page
  before_filter :set_host

  def index
    @page.selected_comment = @page.comments.find_by_id(flash[:selected_comment])
    render :text => @page.render
  end
  
  def create
    comment = @page.comments.build(params[:comment])
    comment.request = request
    comment.save!
    
    ResponseCache.instance.clear
    CommentMailer.deliver_comment_notification(comment) if Radiant::Config['comments.notification'] == "true"
    
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
  
end

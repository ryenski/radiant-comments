class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token
  before_filter :find_page
  before_filter :set_host

  def create
    comment = @page.comments.build(params[:comment])
    comment.request = request
    comment.save!
    
    ResponseCache.instance.clear
    CommentMailer.deliver_comment_notification(comment) if Radiant::Config['comments.notification'] == "true"
    
    redirect_to "#{@page.url}comments/#{comment.id}#comment-#{comment.id}"
  rescue ActiveRecord::RecordInvalid
    @page.request, @page.response = request, response
    @page.last_comment = comment
    render :text => @page.render
  end
  
  def show
    @page.selected_comment = @page.comments.find(params[:id])
    render :text => @page.render
  end
  
  private
  
    def find_page
      @page = Page.find_by_url(params[:url].join("/"))
    end
    
    def set_host
      CommentMailer.default_url_options[:host] = request.host_with_port
    end
  
end

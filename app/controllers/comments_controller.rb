class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    
    @page = Page.find(params[:page_id])
    @comment = @page.comments.build(params[:comment])
    @comment.request = request
    
    TextFilter.descendants.each do |filter| 
      @comment.content_html = filter.filter(@comment.content) if filter.filter_name == @comment.filter_id    
    end
    
    if !@comment.is_spam?
      @comment.save
      ResponseCache.instance.clear
      CommentMailer.deliver_comment_notification if Radiant::Config['comments.notification'] == "true"
    end
    
    redirect_to "#{@page.url}#comment_#{@comment.id}" and return
  end
  
end

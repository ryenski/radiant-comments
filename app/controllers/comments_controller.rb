class CommentsController < ApplicationController
  
  no_login_required
  
  def create
    
    @page = Page.find(params[:page_id])
        
    @comment = Comment.new do |c|
      c.page = @page
      c.author = params[:comment][:author]
      c.author_email = params[:comment][:author_email]
      c.author_url = params[:comment][:author_url]
      c.content = params[:comment][:content]
      c.filter_id = params[:comment][:filter_id]
      c.request = request
    end
    
    TextFilter.descendants.each do |filter| 
      @comment.content_html = filter.filter(@comment.content) if filter.filter_name == @comment.filter_id    
    end
    
    if !@comment.is_spam?
      @comment.save
      # ResponseCache.instance.clear #expire_response(page.url)
      CommentMailer.deliver_comment_notification
    end
    
    redirect_to "#{@page.url}#comment_#{@comment.id}" and return
  end
  
end

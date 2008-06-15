class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    page = Page.find(params[:page_id])
    comment = page.comments.build(params[:comment])
    comment.request = request
    comment.save!
    
    ResponseCache.instance.clear
    CommentMailer.deliver_comment_notification(comment) if Radiant::Config['comments.notification'] == "true"
    
    redirect_to "#{page.url}#comment_saved"
  rescue ActiveRecord::RecordInvalid
    page.request, page.response = request, response
    page.last_comment = comment
    render :text => page.render
  end
  
end

class CommentsController < ApplicationController
  
  no_login_required
  skip_before_filter :verify_authenticity_token  

  def create
    page = Page.find(params[:page_id])
    comment = page.comments.build(params[:comment])
    comment.request = request
    
    if Radiant::Config['comments.filters_enabled'] == "true"
      TextFilter.descendants.each do |filter| 
        comment.content_html = filter.filter(comment.content) if filter.filter_name == comment.filter_id    
      end
    else
      comment.content_html = help.simple_format(help.h(comment.content))
    end
    
    if !comment.is_spam?
      comment.save!
      ResponseCache.instance.clear
      CommentMailer.deliver_comment_notification("http://#{request.host}:#{request.port}/admin/comments?status=unapproved") if Radiant::Config['comments.notification'] == "true"
      redirect_to "#{page.url}#comment_saved"
    else
      redirect_to "#{page.url}#comment_rejected"
    end
  rescue ActiveRecord::RecordInvalid
    page.request, page.response = request, response
    page.last_comment = comment
    render :text => page.render
  end
  
  private
  
    @@help = nil
    def help
      unless @@help
        class << (@@help = Object.new)
          include ERB::Util
          include ActionView::Helpers::TextHelper
          include ActionView::Helpers::TagHelper
          public :h
        end
      end
      @@help
    end
  
end

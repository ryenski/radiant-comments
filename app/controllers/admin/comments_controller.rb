class Admin::CommentsController < ApplicationController
  
  def index
    conditions = case params[:status]
    when "approved"
      "comments.approved_at IS NOT NULL"
    when "unapproved"
      "comments.approved_at IS NULL"
    else
      nil
    end
    @page = Page.find(params[:page_id]) if params[:page_id]
    @comments = @page.nil? ? Comment.paginate(:page => params[:page], :order => "created_at DESC", :conditions => conditions) : @page.comments.paginate(:page => params[:page], :conditions => conditions)
  end
  
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    announce_comment_removed
    ResponseCache.instance.expire_response(@comment.page.url)
    redirect_to :back
  end
  
  def edit
    @comment = Comment.find(params[:id])
  end
  
  def update
    @comment = Comment.find(params[:id])
    begin
      TextFilter.descendants.each do |filter| 
        @comment.content_html = filter.filter(@comment.content) if filter.filter_name == @comment.filter_id    
      end
      @comment.update_attributes(params[:comment])
      ResponseCache.instance.clear
      flash[:notice] = "Comment Saved"
      redirect_to :action => :index
    rescue Exception => e
      flash[:notice] = "There was an error saving the comment"
    end
  end
  
  def enable
    @page = Page.find(params[:page_id])
    @page.enable_comments = 1
    @page.save!
    flash[:notice] = "Comments has been enabled for #{@page.title}"
    redirect_to page_index_path
  end
  
  def approve
    @comment = Comment.find(params[:id])
    @comment.approve!
    ResponseCache.instance.expire_response(@comment.page.url)
    flash[:notice] = "Comment was successfully approved on page #{@comment.page.title}"
    redirect_to :back
  end
  
  def unapprove
    @comment = Comment.find(params[:id])
    @comment.unapprove!
    ResponseCache.instance.expire_response(@comment.page.url)
    flash[:notice] = "Comment was successfully unapproved on page #{@comment.page.title}"
    redirect_to :back
  end
  
  
  protected
  
    def announce_comment_removed
      flash[:notice] = "The comment was successfully removed from the site."
    end
  
end
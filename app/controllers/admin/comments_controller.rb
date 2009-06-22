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
    @comments = if @page.nil? 
      Comment.paginate(:page => params[:page], :order => "created_at DESC", :conditions => conditions)
    else
      @page.comments.paginate(:page => params[:page], :conditions => conditions)
    end

    respond_to do |format|
      format.html
      format.csv  { render :text => @comments.to_csv }
    end
  end

  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy
    announce_comment_removed
    clear_single_page_cache(@comment)
    redirect_to :back
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_comments_path
  end
  
  def destroy_unapproved
    if Comment.destroy_all('approved_at is NULL')
      flash[:notice] = "You have removed all unapproved comments."
    else
      flash[:notice] = "I was unable to remove all unapproved comments."
    end
    redirect_to :back
  end

  def edit
    @comment = Comment.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_comments_path
  end
  def show
    redirect_to edit_admin_comment_path(params[:id])
  end

  def update
    @comment = Comment.find(params[:id])
    begin
      TextFilter.descendants.each do |filter| 
        @comment.content_html = filter.filter(@comment.content) if filter.filter_name == @comment.filter_id    
      end
      @comment.update_attributes(params[:comment])
      Radiant::Cache.clear
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
    flash[:notice] = "Comments have been enabled for #{@page.title}"
    redirect_to admin_pages_url
  end

  def approve
    @comment = Comment.find(params[:id])
    begin
      @comment.approve!
    rescue Comment::AntispamWarning => e
      antispamnotice = "The antispam engine gave a warning: #{e}<br />"
    end
    clear_single_page_cache(@comment)
    flash[:notice] = "Comment was successfully approved on page #{@comment.page.title}" + (antispamnotice ? " (#{antispamnotice})" : "")
    redirect_to :back
  end

  def unapprove
    @comment = Comment.find(params[:id])
    begin
      @comment.unapprove!
    rescue Comment::AntispamWarning => e
      antispamnotice = "The antispam engine gave a warning: #{e}"
    end
    clear_single_page_cache(@comment)
    flash[:notice] = "Comment was successfully unapproved on page #{@comment.page.title}" + (antispamnotice ? " (#{antispamnotice})" : "" )
    redirect_to :back
  end


  protected

  def announce_comment_removed
    flash[:notice] = "The comment was successfully removed from the site."
  end
  
  def clear_single_page_cache(comment)
    if comment && comment.page
      begin
        Radiant::Cache::EntityStore.new.purge(comment.page.url)
        Radiant::Cache::MetaStore.new.purge(comment.page.url)
      rescue NameError
        ResponseCache.instance.clear
      end
    end
  end

end
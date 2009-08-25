class Admin::CommentsController < ApplicationController

  def index
    @comments = load_comments
    respond_to do |format|
      format.html
      format.csv { send_data @comments.to_csv, :filename => "#{File.basename(request.request_uri)}", :type => 'text/csv' }
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
    if Comment.unapproved.destroy_all
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
      @comment.update_attributes!(params[:comment])
      clear_cache
      flash[:notice] = "Comment Saved"
      redirect_to :action => :index
    rescue Exception => e
      flash[:notice] = "There was an error saving the comment: #{e.message}"
      render :action => :edit
    end
  end

  def enable
    @page = Page.find(params[:page_id])
    @page.enable_comments = true
    @page.save!
    clear_cache
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

  def load_comments
    status_scope.paginate(:page => params[:page])
  end

  def status_scope
    case params[:status]
    when 'approved'
      base_scope.approved
    when 'unapproved'
      base_scope.unapproved
    else
      base_scope
    end
  end

  def base_scope
    @page = Page.find(params[:page_id]) if params[:page_id]
    @page ? @page.comments : Comment.recent
  end

  def announce_comment_removed
    flash[:notice] = "The comment was successfully removed from the site."
  end

  def clear_cache
    if defined?(ResponseCache)
      ResponseCache.instance.clear
    else
      Radiant::Cache.clear
    end
  end

  def clear_single_page_cache(comment)
    if comment && comment.page
      clear_cache
    end
  end

end
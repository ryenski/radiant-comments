require 'test/unit'
require File.dirname(__FILE__) + '/../test_helper'

class CommentTest < Test::Unit::TestCase
  # Replace this with your real tests.
  
  def setup
    @controller = Admin::CommentsController.new
    @request = ActionController::TestRequest.new 
    @response = ActionController::TestResponse.new
  end
  
  def test_new_record_should_handle_http
    comment = Comment.new
    assert_equal "http://", comment.author_url
  end
  
  def test_should_remove_http_if_blank
    
  end
  
  def test_snippets_created
    #assert_not_nil Snippet.find_by_name("comments")
    #assert_not_nil Snippet.find_by_name("comment")
    #assert_not_nil Snippet.find_by_name("comment_form")
  end
  
  
  def test_valid_comment
    comment = Comment.new do |c| 
      c.author = "Foo Bar"
      c.author_email = "foo@bar.com"
      c.author_url = "http://www.test.com/"
      c.content = "This is a comment"
    end
    
    assert_valid comment
    
    comment.save
    
    comment_stored = Comment.find_by_author("Foo Bar")
    
    assert_not_nil(comment)
    assert_equal(comment.author, comment_stored.author)
    assert_equal(comment.author_email, comment_stored.author_email)
    assert_equal(comment.author_url, comment_stored.author_url)
    assert_equal(comment.content, comment_stored.content)
  end
  
  def test_enable_comments
    
    page = Page.new do |p|
      p.title = "FOO"
      p.slug = "foo"
      p.breadcrumb = "FOO"
      p.class_name = "Page"
    end
    
    page.save
    
    assert !page.enable_comments
    
    post :enable, :page_id => page.id
    
    assert_response :success
    
    page = Page.find_by_title("FOO")
    
    assert page.enable_comments
    
  end
  
end

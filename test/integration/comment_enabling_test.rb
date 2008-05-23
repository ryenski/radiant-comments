require File.dirname(__FILE__) + '/../test_helper'

class CommentEnablingTest < ActionController::IntegrationTest
  fixtures :users

  def test_should_enable_comments
    post '/admin/welcome/login', :user => {:login => 'admin', :password => 'password'}
    assert_redirected_to '/admin/welcome'

    page = Page.create!(:title => "FOO", :slug => "foo", :breadcrumb => "FOO", :class_name => "Page")
    assert !page.enable_comments
    
    post "/admin/pages/#{page.id}/comments/enable"
    assert_redirected_to '/admin/pages'
    
    assert page.reload.enable_comments    
  end
end
require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::CommentsController do
  dataset :users_and_pages, :comments
  before(:each) do
    login_as :admin
  end

  describe "routing" do
    %w(all approved unapproved).each do |status|
      it "should route to the index action for #{status} comments" do
        params_from(:get, "/admin/comments/#{status}").should == { :controller => "admin/comments", :action => "index", :status => status }
      end
      it "should route to the index action for #{status} comments on the page" do
        params_from(:get, "/admin/pages/1/comments/#{status}").should == { :controller => "admin/comments", :action => "index", :page_id => "1", :status => status }
      end
    end

    it "should route to the destroy_unapproved action" do
      params_from(:delete, "/admin/comments/unapproved/destroy").should == { :controller => "admin/comments", :action => "destroy_unapproved" }
    end

    it "should route to the enable action for the page" do
      params_from(:put, "/admin/pages/1/comments/enable").should == { :controller => "admin/comments", :action => "enable", :page_id => "1" }
    end

    %w(approve unapprove).each do |action|
      it "should route to the #{action} action" do
        params_from(:get, "/admin/comments/1/#{action}").should == { :controller => "admin/comments", :action => action, :id => "1" }
      end
    end
  end

  describe "requesting 'show' with GET" do
    it "should redirect to the comment edit screen" do
      id = comments(:first).id
      get :show, :id => id
      response.should redirect_to("http://test.host/admin/comments/#{id}/edit")
    end
  end
  describe "requesting 'edit' with GET" do
    describe "for an invalid id" do
      it "should redirect to the comments index" do
        get :edit, :id => 999
        response.should redirect_to('http://test.host/admin/comments')
      end
    end
  end
  
  describe "requesting 'destroy' with DELETE" do
    describe "for an invalid id" do
      it "should redirect to the comments index" do
        delete :destroy, :id => 999
        response.should redirect_to('http://test.host/admin/comments')
      end
    end
  end
  
  describe "requesting 'destroy_unapproved' with DELETE" do
    before(:each) do
      request.env['HTTP_REFERER'] = 'http://test.host/admin/comments'
      Comment.count.should > 0
    end
    it "should destroy all of the unapproved comments" do
      Comment.should_receive(:destroy_all).with('approved_at is NULL').and_return(true)
      delete :destroy_unapproved
    end
    it "should leave no unapproved comments in the database" do
      delete :destroy_unapproved
      Comment.count.should == 0
    end
    it "should display the message 'You have removed all unapproved comments.'" do
      delete :destroy_unapproved
      flash[:notice].should == 'You have removed all unapproved comments.'
    end
    it "should redirect to the requesting page" do
      delete :destroy_unapproved
      response.should redirect_to('http://test.host/admin/comments')
    end
  end
end

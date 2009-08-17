require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::CommentsController do
  dataset :users_and_pages, :comments
  before(:each) do
    login_as :admin
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
      Comment.should_receive(:unapproved).and_return(Comment)
      Comment.should_receive(:destroy_all).and_return(true)
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

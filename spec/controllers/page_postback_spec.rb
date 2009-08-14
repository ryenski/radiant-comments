require File.dirname(__FILE__) + '/../spec_helper'

describe SiteController, "Comments form posting to page" do
  dataset :pages
  
  before :each do
    Radiant::Config['comments.post_to_page?'] = true
  end
  
  def do_post(comment_params={})
    post :show_page, :url => "/", :comment => {
      :author => "Jim Gay",
      :author_email => "test@test.com",
      :content => "That's all I have to say about that."
    }.merge(comment_params)
  end
  
  describe "when the comment succeeds in saving" do
    it "should create the comment" do
      lambda { do_post }.should change(Comment, :count).by(1)
    end
    
    it "should redirect back to the page, with the comment anchor" do
      do_post
      response.should be_redirect
      response.redirect_url.should =~ /#comment-\d+$/
    end
  end
  
  describe "when the comment fails to save" do
    before :each do
      @comment_mock = mock_model(Comment)
      Comment.should_receive(:new).and_return(@comment_mock)
      @comment_mock.stub!(:[]=)
      @comment_mock.stub!(:request=)
      @comment_mock.errors.stub!(:full_messages).and_return([])
      @comment_mock.should_receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(@comment_mock))
    end
    
    it "should re-render the page and not cache the result" do
      do_post
      response.should be_success
      response.headers['Cache-Control'].should =~ /private/
    end
    
    it "should assign the failed comment to loaded page" do
      do_post
      assigns[:page].last_comment.should == @comment_mock
    end
  end
end
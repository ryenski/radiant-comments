require File.dirname(__FILE__) + '/../spec_helper'

describe AkismetSpamFilter do
  dataset :comments
  
  before :each do
    @akismet = mock("akismet", :valid? => true, :commentCheck => false)
  end
  
  it "should always allow comments to save" do
    @comment = comments(:first)
    AkismetSpamFilter.valid?(@comment).should be_true
  end
  
  it "should be configured if the api key and blog url are set" do
    Radiant::Config['comments.akismet_key'] = 'foo'
    Radiant::Config['comments.akismet_url'] = 'bar'
    AkismetSpamFilter.should be_configured
  end

  it "should not be configured if either the public or private key are empty" do
    Radiant::Config['comments.akismet_key'] = ''
    Radiant::Config['comments.akismet_url'] = 'bar'
    AkismetSpamFilter.should_not be_configured
    
    Radiant::Config['comments.akismet_key'] = 'foo'
    Radiant::Config['comments.akismet_url'] = ''
    AkismetSpamFilter.should_not be_configured
  end
  
  
  it "should initialize an Akismet API object" do
    AkismetSpamFilter.akismet.should be_kind_of(Akismet)
  end
  
  describe "when approving a comment" do
    before :each do
      @comment = comments(:first)
      AkismetSpamFilter.instance.stub!(:akismet).and_return(@akismet)
    end
    
    it "should be approved when the Akismet API is valid and returns false (message is not spam)" do
      AkismetSpamFilter.should be_approved(@comment)
    end
    
    it "should not be approved when the API is invalid" do
      @akismet.stub!(:valid?).and_return(false)
      AkismetSpamFilter.should_not be_approved(@comment)
    end
    
    it "should not be approved when the API call returns true (message is spam)" do
      @akismet.stub!(:commentCheck).and_return(true)
      AkismetSpamFilter.should_not be_approved(@comment)
    end
    
    it "should not be approved when the API is unreachable" do
      @akismet.stub!(:commentCheck).and_raise(TimeoutError)
      AkismetSpamFilter.should_not be_approved(@comment)
    end
  end
end
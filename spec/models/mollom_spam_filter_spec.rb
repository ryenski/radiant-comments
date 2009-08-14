require File.dirname(__FILE__) + '/../spec_helper'

describe MollomSpamFilter do
  dataset :comments
  
  before :each do
    @mollom_response = mock("response", :ham? => true, :session_id => '00011001')
    @mollom = mock("mollom", :key_ok? => true, :check_content => @mollom_response, :server_list= => '', :server_list => [])
    MollomSpamFilter.instance.instance_variable_set(:@mollom, nil)
  end
  
  it "should always allow comments to save" do
    @comment = comments(:first)
    MollomSpamFilter.valid?(@comment).should be_true
  end
  
  it "should be configured if the public and private key are set" do
    Radiant::Config['comments.mollom_publickey'] = 'foo'
    Radiant::Config['comments.mollom_privatekey'] = 'bar'
    MollomSpamFilter.should be_configured
  end

  it "should not be configured if either the public or private key are empty" do
    Radiant::Config['comments.mollom_publickey'] = ''
    Radiant::Config['comments.mollom_privatekey'] = 'bar'
    MollomSpamFilter.should_not be_configured
    
    Radiant::Config['comments.mollom_publickey'] = 'foo'
    Radiant::Config['comments.mollom_privatekey'] = ''
    MollomSpamFilter.should_not be_configured
  end

  
  it "should initialize a Mollom API object" do
    MollomSpamFilter.mollom.should be_kind_of(Mollom)
  end
  
  it "should load the server list from the cache when possible" do
    Rails.cache.write('MOLLOM_SERVER_CACHE', [{:proto=>"http", :host=>"88.151.243.81"}].to_yaml)
    MollomSpamFilter.mollom.server_list.should == [{:proto=>"http", :host=>"88.151.243.81"}]
  end
  
  describe "when approving a comment" do
    before :each do
      @comment = comments(:first)
      MollomSpamFilter.instance.stub!(:mollom).and_return(@mollom)
    end
    
    it "should not be approved when the Mollom key is invalid" do
      @mollom.stub!(:key_ok?).and_return(false)
      MollomSpamFilter.should_not be_approved(@comment)
    end
    
    it "should not be approved when the response is not ham" do
      @mollom_response.stub!(:ham?).and_return(false)
      MollomSpamFilter.should_not be_approved(@comment)
    end
    
    it "should not be approved when the API is unreachable" do
      @mollom.stub!(:key_ok?).and_raise(Mollom::Error)
      MollomSpamFilter.should_not be_approved(@comment)
    end
    
    it "should be approved when the key is valid and response is ham" do
      MollomSpamFilter.should be_approved(@comment)
    end
    
    it "should cache the Mollom server list after a successful response" do
      Rails.cache.should_receive(:write).with('MOLLOM_SERVER_CACHE', anything())
      MollomSpamFilter.should be_approved(@comment)
    end
  end
  
  describe "when submitting a comment as spam" do
    before :each do
      @comment = comments(:first)
      @comment.mollom_id = '1010101010001'
      MollomSpamFilter.instance.stub!(:mollom).and_return(@mollom)
    end
    
    it "should send the feedback to mollom" do
      @mollom.should_receive(:send_feedback).with(hash_including(:feedback => 'spam')).and_return(true)
      MollomSpamFilter.spam!(@comment)
    end
    
    it "should not submit the spam if the comment has no Mollom response id" do
      @comment.mollom_id = ''
      @mollom.should_not_receive(:send_feedback)
      MollomSpamFilter.spam!(@comment)
    end
    
    it "should not submit the spam if the Mollom key is invalid" do
      @mollom.stub(:key_ok?).and_return(false)
      @mollom.should_not_receive(:send_feedback)
      MollomSpamFilter.spam!(@comment)
    end
    
    it "should raise a antispam error if Mollom raised an error" do
      @mollom.should_receive(:send_feedback).and_raise(Mollom::Error)
      lambda { MollomSpamFilter.spam!(@comment) }.should raise_error(Comment::AntispamWarning)
    end
  end
end
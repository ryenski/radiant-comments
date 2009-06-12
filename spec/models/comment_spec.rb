require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do
  dataset :comments

  before do
    @akismet = mock("akismet", :valid? => true, :commentCheck => false)
    @mollom_response = mock("response", :ham? => true, :session_id => '00011001')
    @mollom = mock("mollom", :key_ok? => false, :check_content => @mollom_response, :server_list= => '')
    @page = pages(:home)
    
    Radiant::Config['comments.auto_approve'] = 'true'
    Akismet.stub!(:new).and_return(@akismet)
    Mollom.stub!(:new).and_return(@mollom)
  end
  
  describe "self.per_page" do
    it "should be 50 when Radiant::Config['comments.per_page'] is not set" do
      Comment.per_page.should == 50
    end
    it "should be 50 when Radiant::Config['comments.per_page'] is 0" do
      Radiant::Config['comments.per_page'] = 0
      Comment.per_page.should == 50
    end
    it "should be the integer value when Radiant::Config['comments.per_page'] is an integer" do
      Radiant::Config['comments.per_page'] = 123
      Comment.per_page.should == 123
    end
    it "should be the absolute value when Radiant::Config['comments.per_page'] is a negative number" do
      Radiant::Config['comments.per_page'] = -99
      Comment.per_page.should == 99
    end
    
  end

  describe "when creating" do
    before do
      @comment = comments(:first)
      @comment.stub!(:using_logic_spam_filter?).and_return(false)
      Radiant::Config['comments.filters_enabled'] = "true"
    end
    
    it "should escape html for content_html when a filter is not selected" do
      @comment.content = %{<script type="text/javascript">alert('hello')</script>}
      @comment.save!
      @comment.content_html.should == %{<p>&lt;script type=&quot;text/javascript&quot;&gt;alert('hello')&lt;/script&gt;</p>}
    end
    it "should sanitize and filter the content for content_html when a filter is selected" do
      @comment.filter_id = 'Textile'
      @comment.content = %{*hello*<script type="text/javascript">alert('hello')</script>}
      @comment.save!
      @comment.content_html.should == %{<p><strong>hello</strong></p>}
    end
    it "should escape the content for content_html when a filter is not selected" do
      Radiant::Config['comments.filters_enabled'] = 'true'
      @comment.filter_id = ''
      @comment.content = %{*hello*<script type="text/javascript">alert('hello')</script>}
      @comment.save!
      @comment.content_html.should == %{<p>*hello*&lt;script type=&quot;text/javascript&quot;&gt;alert('hello')&lt;/script&gt;</p>}
    end

    it "should successfully create comment" do
      @comment.valid?.should be_true
      lambda{@comment.save!}.should_not raise_error
    end

    it "should set content_html with filter when saving" do
      @comment.save

      @comment.content_html.should eql("<p>That's all I have to say about that.</p>")
    end

    it "should auto_approve the comment if it is valid according to Akismet" do
      @akismet.should_receive(:valid?).and_return(true)
      @akismet.should_receive(:commentCheck).and_return(false) # False is good here :)

      @comment.save

      @comment.approved_at.should_not be_nil
      @comment.approved_at.should be_instance_of(Time)
    end

    it "should NOT auto_approve the comment if it is INVALID" do
      @akismet.should_receive(:valid?).and_return(true)
      @akismet.should_receive(:commentCheck).and_return(true)

      @comment.save

      @comment.approved_at.should be_nil
    end

    it "should auto_approve the comment if it is valid according to Mollom" do
      @akismet.should_receive(:valid?).and_return(false)
      @mollom.should_receive(:key_ok?).at_least(1).times.and_return(true)
      @mollom.should_receive(:check_content).and_return(@mollom_response)

      @comment.save!

      @comment.approved_at.should_not be_nil
      @comment.approved_at.should be_instance_of(Time)
    end

    it "should save the mollom servers if the key is valid" do
      @akismet.should_receive(:valid?).and_return(false)
      @mollom.should_receive(:key_ok?).at_least(1).times.and_return(true)
      @mollom.should_receive(:check_content).and_return(@mollom_response)
      @mollom.should_receive(:server_list).at_least(1).times.and_return({:server1 => "one", :server2 => "two"})
      Rails.cache.read('MOLLOM_SERVER_CACHE').should be_blank
      @cache = Rails.cache.stub!(:read).with('MOLLOM_SERVER_CACHE').and_return(@mollom.server_list.to_yaml)
      @cache.stub!(:blank?).and_return(true)
      @mollom.should_receive(:server_list=).at_least(1).times
      @comment.save!
      Rails.cache.read('MOLLOM_SERVER_CACHE').should == @mollom.server_list.to_yaml
    end

    it "should NOT save the mollom servers if the key is INVALID" do
      @akismet.should_receive(:valid?).and_return(false)
      @mollom.should_receive(:key_ok?).at_least(1).times.and_return(false)
      
      Rails.cache.should_not_receive(:write)
      @comment.spam_answer = nil
      @comment.valid_spam_answer = nil
      @comment.save!
    end

    it "should validate that author is supplied" do
      comment = create_comment(:author => nil)
      comment.valid?.should be_false
    end

    it "should validate that author_email is supplied" do
      comment = create_comment(:author_email => nil)
      comment.valid?.should be_false
    end

    it "should validate that content is supplied" do
      comment = create_comment(:content => nil)
      comment.valid?.should be_false
    end

  end
  
  describe "not using spam answer" do
    it "should save a comment" do
      @comment = comments(:first)
      @comment.spam_answer = nil
      @comment.valid_spam_answer = nil
      lambda { @comment.save! }.should_not raise_error
    end
  end

  describe "using spam answer" do
    it "should error that the 'Spam answer is not correct' when saved with a spam_answer and valid_spam_answer that do not match" do
      @comment = comments(:first)
      @comment.valid_spam_answer = 'TRUE'
      @comment.spam_answer = 'FALSE'
      @comment.send(:using_logic_spam_filter?).should be_true
      lambda{ @comment.save! }.should raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Spam answer is not correct.')
    end
    it "should allow differing capitalization and punctuation in the answers when comparing" do
      @comment = comments(:first)
      correct_answer = "that's   THE    way it ought to be!".to_slug
      hashed_answer = Digest::MD5.hexdigest(correct_answer)
      @comment.valid_spam_answer = hashed_answer
      @comment.spam_answer = "That's the way it ought to be!"
      
      lambda{ @comment.save! }.should_not raise_error
    end
  end

  def create_comment(opts={})
    Comment.new({ :page => @page, :author => "Test", :author_email => "test@test.com", :author_ip => "10.1.10.1",
                  :content => "Test..." }.merge(opts))
  end

  def page_params(attributes={})
    title = attributes[:title] || unique_page_title

    attributes = {
      :title => title,
      :breadcrumb => title,
      :slug => title.symbolize.to_s.gsub("_", "-"),
      :class_name => nil,
      :status_id => Status[:published].id,
      :published_at => Time.now.to_s(:db)
    }.update(attributes)
    attributes[:parent_id] = 10
    attributes
  end

  @@unique_page_title_call_count = 0
  def unique_page_title
    @@unique_page_title_call_count += 1
    "Page #{@@unique_page_title_call_count}"
  end

end

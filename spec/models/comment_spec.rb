require File.dirname(__FILE__) + '/../spec_helper'

describe Comment do

  before do
    @akismet = mock("akismet", :valid? => true, :commentCheck => false)
    @mollom_response = mock("response", :ham? => true, :session_id => '00011001')
    @mollom = mock("mollom", :key_ok? => false, :check_content => @mollom_response)
    @page = Page.create(page_params(:title => "Test"))

    Akismet.stub!(:new).and_return(@akismet)
    Mollom.stub!(:new).and_return(@mollom)
  end

  after do
    Page.find(:all).each { |page| page.destroy }
    Comment.find(:all).each { |comment| comment.destroy }
  end

  describe Comment, "when creating" do

    it "should successfully create comment" do
      comment = create_comment

      comment.valid?.should be_true
      comment.save.should be_true
    end

    it "should set content_html with filter when saving" do
      comment = create_comment
      comment.save

      comment.content_html.should eql('<p>Test...</p>')
    end

    it "should auto_approve the comment if it is valid according to Akismet" do
      @akismet.should_receive(:valid?).and_return(true)
      @akismet.should_receive(:commentCheck).and_return(false) # False is good here :)

      comment = create_comment
      comment.save

      comment.approved_at.should_not be_nil
      comment.approved_at.should be_instance_of(Time)
    end

    it "should NOT auto_approve the comment if it is INVALID" do
      @akismet.should_receive(:valid?).and_return(true)
      @akismet.should_receive(:commentCheck).and_return(true)

      comment = create_comment
      comment.save

      comment.approved_at.should be_nil
    end

    it "should auto_approve the comment if it is valid according to Mollom" do
      @akismet.should_receive(:valid?).and_return(false)
      @mollom.should_receive(:key_ok?).at_least(1).times.and_return(true)
      @mollom.should_receive(:check_content).and_return(@mollom_response)

      File.stub!(:open)

      comment = create_comment
      comment.save

      comment.approved_at.should_not be_nil
      comment.approved_at.should be_instance_of(Time)
    end

    it "should save the mollom servers if the key is valid" do
      @akismet.should_receive(:valid?).and_return(false)
      @mollom.should_receive(:key_ok?).at_least(1).times.and_return(true)
      @mollom.should_receive(:check_content).and_return(@mollom_response)
      @mollom.should_receive(:server_list).and_return({:server1 => "one", :server2 => "two"})
      
      io = mock("io")
      io.should_receive(:write).with({:server1 => "one", :server2 => "two"}.to_yaml)
      File.should_receive(:open).and_yield(io)

      comment = create_comment
      comment.save
    end

    it "should NOT save the mollom servers if the key is INVALID" do
      @akismet.should_receive(:valid?).and_return(false)
      @mollom.should_receive(:key_ok?).at_least(1).times.and_return(false)

      File.should_not_receive(:open)

      comment = create_comment
      comment.save
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

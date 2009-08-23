require File.dirname(__FILE__) + '/../spec_helper'

describe "Comment" do
  dataset :comments

  before do
    @page = pages(:home)
    Radiant::Config['comments.auto_approve'] = 'true'
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
      @comment.content_html.should == %{<p>alert(&#39;hello&#39;)</p>}
    end
    it "should sanitize the content" do
      @comment.content = %{*hello* <script type="text/javascript">alert('hello')</script>}
      @comment.save!
      @comment.content_html.should_not include_text('script')
    end
    it "should filter the content for content_html when a filter is selected" do
      @comment.filter_id = 'Textile'
      @comment.content = %{*hello* <script type="text/javascript">alert('hello')</script>}
      @comment.save!
      @comment.content_html.should match(/<strong>hello<\/strong>/)
    end
    it "should escape the content for content_html when a filter is not selected" do
      Radiant::Config['comments.filters_enabled'] = 'true'
      @comment.filter_id = ''
      @comment.content = %{*hello* <script type="text/javascript">alert('hello')</script>}
      @comment.save!
      @comment.content_html.should_not include_text('script')
    end

    it "should successfully create comment" do
      @comment.valid?.should be_true
      lambda{@comment.save!}.should_not raise_error
    end

    it "should set content_html with filter when saving" do
      @comment.save
      @comment.content_html.should eql("<p>That&#39;s all I have to say about that.</p>")
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

    it "should add a http:// prefix when author_url does not include a protocol" do
      url = 'www.example.com'
      @comment.author_url = url
      @comment.save!
      @comment.author_url.should == "http://#{url}"
    end

    it "should not alter author_url with a http:// prefix" do
      url = 'http://www.example.com'
      @comment.author_url = url
      @comment.save!
      @comment.author_url.should == url
    end

    it "should not alter author_url with a https:// prefix" do
      url = 'https://www.example.com'
      @comment.author_url = url
      @comment.save!
      @comment.author_url.should == url
    end

    it "should encode special characters in author_url" do
      url = 'http://example.com/~foo/q?a=1&b=2'
      @comment.author_url = url
      @comment.save!
      @comment.author_url.should == CGI.escapeHTML(url)
    end
    
    it "should not alter author_url with a HTTP:// prefix" do
      url = 'HTTP://Www.Example.Com'
      @comment.author_url = url
      @comment.save!
      @comment.author_url.should == url
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

require File.dirname(__FILE__) + '/../spec_helper'

describe Page do
  dataset :users_and_pages, :comments
  
  describe "r:comments:field:spam_answer_tag" do
    it "should render the spam_answer input and the valid_spam_answer hidden input" do
      answer_as_set = 'no spam'
      correct_answer = Digest::MD5.hexdigest(answer_as_set.to_slug)
      pages(:home).should render("<r:comments:field:spam_answer_tag answer='#{answer_as_set}' />").as(%{<input type="text" id="comment_spam_answer" name="comment[spam_answer]" value=""  /><input type="hidden" name="comment[valid_spam_answer]" value="#{correct_answer}" />})
    end
  end
  describe "r:if_comments_simple_spam_filter_enabled" do
    it "should render the content when required in Radiant::Config" do
      Radiant::Config['comments.simple_spam_filter_required?'] = true
      tag = %{<r:if_comments_simple_spam_filter_enabled>foo</r:if_comments_simple_spam_filter_enabled>}
      expected = 'foo'
      pages(:home).should render(tag).as(expected)
    end
    it "should not render the content when not required in Radiant::Config" do
      Radiant::Config['comments.simple_spam_filter_required?'] = false
      tag = %{<r:if_comments_simple_spam_filter_enabled>foo</r:if_comments_simple_spam_filter_enabled>}
      expected = ''
      pages(:home).should render(tag).as(expected)
    end
  end
  describe "r:unless_comments_use_simple_spam_filter" do
    it "should not render the content when required in Radiant::Config" do
      Radiant::Config['comments.simple_spam_filter_required?'] = true
      tag = %{<r:unless_comments_simple_spam_filter_enabled>foo</r:unless_comments_simple_spam_filter_enabled>}
      expected = ''
      pages(:home).should render(tag).as(expected)
    end
    it "should render the content when not required in Radiant::Config" do
      Radiant::Config['comments.simple_spam_filter_required?'] = false
      tag = %{<r:unless_comments_simple_spam_filter_enabled>foo</r:unless_comments_simple_spam_filter_enabled>}
      expected = 'foo'
      pages(:home).should render(tag).as(expected)
    end
  end
  describe "<r:comments:form>" do
    before :each do
      @page = pages(:first)
    end
    it "should postback to the comments controller by default" do
      Radiant::Config['comments.post_to_page?'] = false
      @page.should render('<r:comments:form></r:comments:form>').matching(%r[#{@page.url}comments])
    end
    
    it "should postback to the page when comments.post_to_page? is set to true" do
      Radiant::Config['comments.post_to_page?'] = true
      @page.should render('<r:comments:form></r:comments:form>').matching(%r[#{@page.url}"])
    end
  end
end

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
end
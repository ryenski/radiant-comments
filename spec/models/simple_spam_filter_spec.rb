require File.dirname(__FILE__) + '/../spec_helper'

describe SimpleSpamFilter do
  dataset :comments

  before :each do
    @comment = comments(:first)
    Radiant::Config['comments.simple_spam_filter_required?'] = true
  end

  it "should always approve comments (they passed validation already)" do
    SimpleSpamFilter.should be_approved(@comment)
  end

  it "should validate the comment when the challenge is not defined and not required" do
    Radiant::Config['comments.simple_spam_filter_required?'] = false
    @comment.valid_spam_answer.should be_nil
    @comment.spam_answer.should be_nil
    SimpleSpamFilter.valid?(@comment).should be_true
  end

  it "should not validate the comment when the response does not match the challenge" do
    @comment.valid_spam_answer = 'TRUE'
    @comment.spam_answer = 'FALSE'
    SimpleSpamFilter.valid?(@comment).should be_false
    @comment.errors.full_messages.to_sentence.should =~ /Spam answer/
  end

  it "should validate the comment when the response matches the challenge" do
    correct_answer = "that's   THE    way it ought to be!".to_slug
    hashed_answer = Digest::MD5.hexdigest(correct_answer)
    @comment.valid_spam_answer = hashed_answer
    @comment.spam_answer = correct_answer
    SimpleSpamFilter.valid?(@comment).should be_true
  end

  it "should allow differing capitalization and punctuation in the response" do
    correct_answer = "that's   THE    way it ought to be!".to_slug
    hashed_answer = Digest::MD5.hexdigest(correct_answer)
    @comment.valid_spam_answer = hashed_answer
    @comment.spam_answer = "That's the way it ought to be!"
    SimpleSpamFilter.valid?(@comment).should be_true
  end
end
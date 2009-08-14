require File.dirname(__FILE__) + '/../spec_helper'

describe SimpleSpamFilter do
  dataset :comments

  before :each do
    @comment = comments(:first)
    Radiant::Config['comments.simple_spam_filter_required?'] = true
  end

  it "should approve the comment when the challenge is not defined and not required" do
    Radiant::Config['comments.simple_spam_filter_required?'] = false
    @comment.valid_spam_answer.should be_nil
    @comment.spam_answer.should be_nil
    SimpleSpamFilter.should be_approved(@comment)
  end

  it "should not approve the comment when the response does not match the challenge" do
    @comment.valid_spam_answer = 'TRUE'
    @comment.spam_answer = 'FALSE'
    SimpleSpamFilter.should_not be_approved(@comment)
    @comment.errors.full_messages.to_sentence.should =~ /Spam answer/
  end

  it "should approve the comment when the response matches the challenge" do
    correct_answer = "that's   THE    way it ought to be!".to_slug
    hashed_answer = Digest::MD5.hexdigest(correct_answer)
    @comment.valid_spam_answer = hashed_answer
    @comment.spam_answer = correct_answer
    SimpleSpamFilter.should be_approved(@comment)
  end

  it "should allow differing capitalization and punctuation in the response" do
    correct_answer = "that's   THE    way it ought to be!".to_slug
    hashed_answer = Digest::MD5.hexdigest(correct_answer)
    @comment.valid_spam_answer = hashed_answer
    @comment.spam_answer = "That's the way it ought to be!"
    SimpleSpamFilter.should be_approved(@comment)
  end
end
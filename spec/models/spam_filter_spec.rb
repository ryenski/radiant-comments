require File.dirname(__FILE__) + '/../spec_helper'

describe SpamFilter do
  dataset :comments
  
  it "should be a Simpleton" do
    SpamFilter.included_modules.should include(Simpleton)
  end
  
  it "should require subclasses to implement the approved? method" do
    lambda { SpamFilter.approved?(comments(:first)) }.should raise_error(NotImplementedError)
  end
  
  it "should access the proper subclass by name" do
    SpamFilter['simple'].should == SimpleSpamFilter
    SpamFilter['mollom'].should == MollomSpamFilter
    SpamFilter['akismet'].should == AkismetSpamFilter
    SpamFilter['foo'].should be_nil
  end
  
  it "should accept a comment as spam and do nothing" do
    lambda { SpamFilter.spam!(comments(:first)) }.should_not raise_error
  end
  
  it "should not be configured by default" do
    SpamFilter.should_not be_configured
  end
end
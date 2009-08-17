require File.dirname(__FILE__) + '/../spec_helper'

describe SpamFilter do
  dataset :comments
  
  it "should be a Simpleton" do
    SpamFilter.included_modules.should include(Simpleton)
  end
  
  it "should require subclasses to implement the approved? method" do
    lambda { SpamFilter.approved?(comments(:first)) }.should raise_error(NotImplementedError)
  end
  
  it "should accept a comment as spam and do nothing" do
    lambda { SpamFilter.spam!(comments(:first)) }.should_not raise_error
  end
  
  it "should not be configured by default" do
    SpamFilter.should_not be_configured
  end
  
  describe "selecting an appropriate subclass" do
    it "should select the Simple filter if no other filters are configured" do
      SpamFilter.descendants.without(SimpleSpamFilter).each do |f|
        f.stub!(:configured?).and_return(false)
      end
      SpamFilter.select.should == SimpleSpamFilter
    end
    
    it "should select the first properly configured filter" do
      MollomSpamFilter.stub!(:configured?).and_return(true)
      SpamFilter.descendants.without(MollomSpamFilter).each do |f|
        f.stub!(:configured?).and_return(false)
      end
      SpamFilter.select.should == MollomSpamFilter
    end
  end
end
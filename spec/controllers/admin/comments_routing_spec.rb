require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::CommentsController do
  dataset :users_and_pages, :comments
  before(:each) do
    login_as :admin
  end

  describe "routing" do
    it "should route to unapproved comments by default" do
      params_from(:get, "/admin/comments").should == { :controller => "admin/comments", :action => "index", :status => 'unapproved' }
    end
    
    %w(all approved unapproved).each do |status|
      it "should route to the index action for #{status} comments" do
        params_from(:get, "/admin/comments/#{status}").should == { :controller => "admin/comments", :action => "index", :status => status }
      end
      it "should route to the index action for #{status} comments on the page" do
        params_from(:get, "/admin/pages/1/comments/#{status}").should == { :controller => "admin/comments", :action => "index", :page_id => "1", :status => status }
      end
      it "should route to the index action for #{status} comments with the csv format" do
        params_from(:get, "/admin/comments/#{status}.csv").should == { :controller => "admin/comments", :action => "index", :status => status, :format => 'csv' }
      end
      it "should route to the index action for #{status} comments on the page with the csv format" do
        params_from(:get, "/admin/pages/1/comments/#{status}.csv").should == { :controller => "admin/comments", :action => "index", :status => status, :page_id => "1", :format => 'csv' }
      end
    end

    it "should route to the destroy_unapproved action" do
      params_from(:delete, "/admin/comments/destroy_unapproved").should == { :controller => "admin/comments", :action => "destroy_unapproved" }
    end

    it "should route to the enable action for the page" do
      params_from(:put, "/admin/pages/1/comments/enable").should == { :controller => "admin/comments", :action => "enable", :page_id => "1" }
    end

    %w(approve unapprove).each do |action|
      it "should route to the #{action} action" do
        params_from(:put, "/admin/comments/1/#{action}").should == { :controller => "admin/comments", :action => action, :id => "1" }
      end
    end
  end
end

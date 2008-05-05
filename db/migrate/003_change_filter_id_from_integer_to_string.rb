class ChangeFilterIdFromIntegerToString < ActiveRecord::Migration
  def self.up
    change_column "comments", "filter_id", :string, :limit => 25
  end
  
  def self.down
    change_column "comments", "filter_id", :integer
  end
end


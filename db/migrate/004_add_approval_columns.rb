# rake production radiant:extensions:comments:migrate
class AddApprovalColumns < ActiveRecord::Migration
  def self.up
    add_column :comments, :approved_at, :datetime
    add_column :comments, :approved_by, :integer
  end
  
  def self.down
    remove_column :comments, :approved_by
    remove_column :comments, :approved_at
  end
end


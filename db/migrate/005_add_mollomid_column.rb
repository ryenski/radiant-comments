# rake production radiant:extensions:comments:migrate
class AddMollomidColumn < ActiveRecord::Migration
  def self.up
    add_column :comments, :mollom_id, :string
  end
  
  def self.down
    remove_column :comments, :mollom_id
  end
end


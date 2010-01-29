class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.column :page_id, :integer
      t.column :author, :string
      t.column :author_url, :string
      t.column :author_email, :string
      t.column :author_ip, :string
      t.column :content, :text
      t.column :content_html, :text
      t.column :created_at, :datetime
      t.column :updated_at, :datetime
      t.column :filter_id, :integer
      t.column :user_agent, :string
      t.column :referrer, :string
    end
    
    add_column :pages, :enable_comments, :boolean, :default => false
    add_column :pages, :comments_count,  :integer, :default => 0
    Page.reset_column_information
    Page.update_all("comments_count = 0")
  end
  
  def self.down
    drop_table :comments
    remove_column :pages, :enable_comments
    remove_column :pages, :comments_count
  end
end
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
    
    add_column :pages, :enable_comments, :boolean
    add_column :pages, :comments_count,  :integer, :default => 0
    execute "UPDATE pages SET comments_count = 0"
    
    # Uses Approval plugin
    # Uncomment these lines to enable support for the RequiresApproval plugin
    # http://svn.artofmission.com/svn/plugins/requires_approval
    
    # create_table :approval_statuses do |t|
    #   t.column :name, :string
    #   t.column :publish, :boolean
    # end
    # 
    # create_table :approvals do |t|
    #   t.column :approvable_type, :string
    #   t.column :approvable_id, :integer
    #   t.column :approval_status_id, :integer
    #   t.column :created_at, :datetime
    #   t.column :created_by, :integer
    #   t.column :expires_at, :datetime
    # end
  end
  
  def self.down
    drop_table :comments
    # drop_table :approvals
    # drop_table :approval_statuses
    remove_column :pages, :enable_comments
    remove_column :pages, :comments_count
  end
end
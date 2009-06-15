class CommentsDataset < Dataset::Base
  uses :pages
  
  def load
    create_record Comment, :first, :page_id => pages(:home).id, :author => 'Jim Gay', :author_email => 'test@spec.com', :content => "That's all I have to say about that."
  end
end
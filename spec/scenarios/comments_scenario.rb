class CommentsScenario < Scenario::Base
  uses :pages
  
  def load
    create_record Comment, :first, :page_id => 1, :author => 'Jim Gay', :author_email => 'test@spec.com', :content => "That's all I have to say about that."
  end
end
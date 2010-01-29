class CreateSnippets < ActiveRecord::Migration
  def self.up
    
    # This code _WILL_ override snippets with the name comments, comment and comment_form
    # if they exists.
    
    # Comments snippet
    Snippet.new do |s|
      s.name = "comments"
      s.content = <<CONTENT
<r:if_comments>
  <div class="comments">
    <h2>Comments</h2>
    <r:comments:each>
      <r:snippet name="comment" />
    </r:comments:each>
  </div>
</r:if_comments>
<r:snippet name="comment_form" />
CONTENT
    end.save

    # Comment snippet
    Snippet.new do |s|
      s.name = "comment"
      s.content = <<CONTENT
<r:comments:field>
  <div class="comment" id="comment-<r:id/>">
    <p class="author">
      <r:if_author_url><a href="<r:author_url/>" title="Visit <r:author/>'s website"></r:if_author_url>
      <r:author/>
      <r:if_author_url></a></r:if_author_url>
      said on <r:date/>:
    </p>
    
    <div class="content_html"><r:content_html /></div>
    
    <r:if_selected><p><em>
      <r:if_approved>Thanks for your comment!</r:if_approved>
      <r:unless_approved>Thanks for your comment, it has gone into the moderation queue and will be dealt with shortly.</r:unless_approved>
    </em></p></r:if_selected>
  </div>
</r:comments:field>
CONTENT
    end.save
    
    # comment_spam_block snippet
    Snippet.new do |s|
      s.name = 'comment_spam_block'
      s.content = <<CONTENT
<r:random>
  <r:error on="spam_answer"><p style="color:red">Answer <r:message /></p></r:error>
  <r:option>
    <p><label for="comment_spam_answer">What day of the week has the letter "h" in it's name?</label> (required)<br />
    <r:spam_answer_tag answer="Thursday" /></p>
  </r:option>
  <r:option>
    <p><label for="comment_spam_answer">Yellow and blue together make what color?</label> (required)<br />
    <r:spam_answer_tag answer="green" /></p>
  </r:option>
  <r:option>
    <p><label for="comment_spam_answer">What is SPAM spelled backwards?</label> (required)<br />
    <r:spam_answer_tag answer="MAPS" /></p>
  </r:option>
</r:random>
CONTENT
    end.save

    # Comment_form snippet
    Snippet.new do |s|
      s.name = "comment_form"
      s.content = <<CONTENT
<r:page>
  <r:if_enable_comments>
    <r:comments:form>
      <h3>Post a comment</h3>
      <r:error><p style="color:red">Please correct the errors below.</p></r:error>
      <p><label for="comment_author">Your Name</label><br />
      <r:error on="author"><p style="color:red">Name <r:message /></p></r:error>
      <p><r:text_field_tag name="author" id="author" class="required" /></p>

      <p><label for="comment_author_email">Your Email Address</label> (required, but not displayed)<br />
      <r:error on="author_email"><p style="color:red">Email <r:message /></p></r:error>
      <p><r:text_field_tag name="author_email" class="required" /></p>

      <p><label for="comment_author_url">Your Web Address</label> (optional)<br />
      <r:error on="author_url"><p style="color:red">Web Address <r:message /></p></r:error>
      <p><r:text_field_tag name="author_url" /></p>

      <p><label for="comment_content">Your Comment</label><br />
      <r:error on="content"><p style="color:red">Comment <r:message /></p></r:error>
      <label for="comment_filter_id">Filter: <r:filter_box_tag name="filter_id" value="Textile" /></label><br />
      <p><r:text_area_tag name="content" class="required" rows="9" cols="40" /></p>

      <r:if_comments_simple_spam_filter_enabled>
        <r:snippet name="comment_spam_block" />
      </r:if_comments_simple_spam_filter_enabled>

      <r:submit_tag name="submit" value="Save Comment" />

    </r:comments:form>
  </r:if_enable_comments>
</r:page>
CONTENT
    end.save
  end
  
  def self.down
    
    ["comments", "comment", "comment_form", "comment_spam_block"].each do |snippet|
      Snippet.find_by_name(snippet).destroy rescue p "Could not destroy snippet #{snippet}"
    end
   
  end
end

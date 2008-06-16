module CommentTags
  include Radiant::Taggable
  
  desc "Provides tags and behaviors to support comments in Radiant."
  
  desc %{
    Renders the contained elements if comments are enabled on the page. 
  }
  tag "if_enable_comments" do |tag|
    tag.expand if (tag.locals.page.enable_comments?)
  end
  
  desc %{
    Renders the contained elements if the page has comments. 
  }
  tag "if_comments" do |tag|
    tag.expand if tag.locals.page.approved_comments.count > 0
  end
  
  desc %{ 
    Gives access to comment-related tags
  }
  tag "comments" do |tag|
    comments = tag.locals.page.approved_comments
    tag.expand
  end
  
  desc %{
    Cycles through each comment and renders the enclosed tags for each. 
  }
  tag "comments:each" do |tag|
    comments = tag.locals.page.approved_comments
    result = []
    comments.each do |comment|
      tag.locals.comment = comment
      result << tag.expand
    end
    result
  end
  
  desc %{
    Gives access to the particular fields for each comment. 
  }
  tag "comments:field" do |tag|
    tag.expand
  end
  
  %w(id author author_email author_url content content_html filter_id).each do |field|
    desc %{ Print the value of the #{field} field for this comment. }
    tag "comments:field:#{field}" do |tag|
      options = tag.attr.dup
      #options.inspect
      tag.locals.comment.send(field)
    end
  end
  
  desc %{
    Renders the date a comment was created. 
    
    *Usage:* 
    <pre><code><r:date [format="%A, %B %d, %Y"] /></code></pre>
  }
  tag 'comments:field:date' do |tag|
    comment = tag.locals.comment
    format = (tag.attr['format'] || '%A, %B %d, %Y')
    date = comment.created_at
    date.strftime(format)
  end
  
  desc %{
    Renders the contained elements if the comment has an author_url specified.
  }
  tag "comments:field:if_author_url" do |tag|
    tag.expand unless tag.locals.comment.author_url.blank?
  end
  
  desc %{
    Renders a comment form. 
    
    *Usage:*
    <r:comment:form>...</r:comment:form>
  }
  tag "comments:form" do |tag|
    @tag_attr = { :class => "comment_form" }.update( tag.attr.symbolize_keys )
    results = %Q{
      <a name="comment"></a>
      <a name="comment_saved"></a>
      <form action="/pages/#{tag.locals.page.id}/comments#comment" method="post" id="comment_form">
        <div id="comment_saved" style="display:none">Thanks for your comment!</div>
        <script type="text/javascript">if($ && location.hash == '#comment_saved'){$('comment_saved').show();}</script>
        #{tag.expand}
      </form>
    }
  end
  
  tag 'comments:error' do |tag|
    if comment = tag.locals.page.last_comment
      if on = tag.attr['on']
        if error = comment.errors.on(on)
          tag.locals.error_message = error
          tag.expand
        end
      else
        tag.expand if !comment.valid?
      end
    end
  end
  
  tag 'comments:error:message' do |tag|
    tag.locals.error_message
  end

  %w(text password hidden).each do |type|
    desc %{Builds a #{type} form field for comments.}
    tag "comments:#{type}_field_tag" do |tag|
      attrs = tag.attr.symbolize_keys
      r = %{<input type="#{type}"}
      r << %{ id="comment_#{attrs[:name]}"}
      r << %{ name="comment[#{attrs[:name]}]"}
      r << %{ class="#{attrs[:class]}"} if attrs[:class]
      if value = (tag.locals.page.last_comment ? tag.locals.page.last_comment.send(attrs[:name]) : attrs[:value])
        r << %{ value="#{value}" }
      end
      r << %{ />}
    end
  end
  
  %w(submit reset).each do |type|
    desc %{Builds a #{type} form button for comments.}
    tag "comments:#{type}_tag" do |tag|
      attrs = tag.attr.symbolize_keys
      r = %{<input type="#{type}"}
      r << %{ id="#{attrs[:name]}"}
      r << %{ name="#{attrs[:name]}"}
      r << %{ class="#{attrs[:class]}"} if attrs[:class]
      r << %{ value="#{attrs[:value]}" } if attrs[:value]
      r << %{ />}
    end
  end
  
  desc %{Builds a text_area form field for comments.}
  tag "comments:text_area_tag" do |tag|
    attrs = tag.attr.symbolize_keys
    r = %{<textarea}
    r << %{ id="comment_#{attrs[:name]}"}
    r << %{ name="comment[#{attrs[:name]}]"}
    r << %{ class="#{attrs[:class]}"} if attrs[:class]
    r << %{ rows="#{attrs[:rows]}"} if attrs[:rows]
    r << %{ cols="#{attrs[:cols]}"} if attrs[:cols]
    r << %{>}
    if content = (tag.locals.page.last_comment ? tag.locals.page.last_comment.send(attrs[:name]) : attrs[:content])
      r << content
    end
    r << %{</textarea>}
  end
  
  desc %{Build a drop_box form field for the filters avaiable.}
  tag "comments:filter_box_tag" do |tag|
    attrs = tag.attr.symbolize_keys
    r =  %{<select name="comment[#{attrs[:name]}]"}
    r << %{ size="#{attrs[:size]}"} if attrs[:size]
    r << %{>}
    
    TextFilter.descendants.each do |filter| 
      
      r << %{<option value="#{filter.filter_name}"}
      r << %{ selected } if attrs[:value] == filter.filter_name
      r << %{>#{filter.filter_name}</option>}
      
    end
      
    r << %{</select>}
  end
  
  desc %{Prints the number of comments. }
  tag "comments:count" do |tag|
    tag.locals.page.approved_comments.count
  end
end

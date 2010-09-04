module CommentTags
  include Radiant::Taggable

  desc "Provides tags and behaviors to support comments in Radiant."

  desc %{
    Renders the contained elements if comments are enabled on the page.
  }
  tag "if_enable_comments" do |tag|
    tag.expand if (tag.locals.page.enable_comments?)
  end
  # makes more sense to me
  tag "if_comments_enabled" do |tag|
    tag.expand if (tag.locals.page.enable_comments?)
  end
  
  desc %{
    Renders the contained elements unless comments are enabled on the page.
  }
  tag "unless_enable_comments" do |tag|
    tag.expand unless (tag.locals.page.enable_comments?)
  end
  
  # makes more sense to me
  tag "unless_comments_enabled" do |tag|
    tag.expand unless (tag.locals.page.enable_comments?)
  end
  
  desc %{
    Renders the contained elements if the page has comments.
  }
  tag "if_comments" do |tag|
    tag.expand if tag.locals.page.has_visible_comments?
  end

  desc %{
    Renders the contained elements unless the page has comments. 
  }
  tag "unless_comments" do |tag|
    tag.expand unless tag.locals.page.has_visible_comments?
  end
  
  desc %{
    Renders the contained elements if the page has comments _or_ comment is enabled on it.
  }
  tag "if_comments_or_enable_comments" do |tag|
    tag.expand if(tag.locals.page.has_visible_comments? || tag.locals.page.enable_comments?)
  end

  desc %{
    Gives access to comment-related tags
  }
  tag "comments" do |tag|
    comments = tag.locals.page.comments.approved
    tag.expand
  end

  desc %{
    Cycles through each comment and renders the enclosed tags for each.
  }
  tag "comments:each" do |tag|
    page = tag.locals.page
    comments = page.comments.approved.to_a
    comments << page.selected_comment if page.selected_comment && page.selected_comment.unapproved?
    result = []
    comments.each_with_index do |comment, index|
      tag.locals.comment = comment
      tag.locals.index = index
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
  
  desc %{
    Renders the index number for this comment.
  }
  tag 'comments:field:index' do |tag|
    tag.locals.index + 1
  end
  
  %w(id author author_email author_url content content_html filter_id).each do |field|
    desc %{ Print the value of the #{field} field for this comment. }
    tag "comments:field:#{field}" do |tag|
      options = tag.attr.dup
      #options.inspect
      value = tag.locals.comment.send(field)
      value
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
    Renders a link if there's an author_url, otherwise just the author's name.
  }
  tag "comments:field:author_link" do |tag|
    if tag.locals.comment.author_url.blank?
      tag.locals.comment.author
    else
      %(<a href="#{tag.locals.comment.author_url}">#{tag.locals.comment.author}</a>)
    end
  end

  desc %{
    Renders the contained elements if the comment has an author_url specified.
  }
  tag "comments:field:if_author_url" do |tag|
    tag.expand unless tag.locals.comment.author_url.blank?
  end

  desc %{
    Renders the contained elements if the comment is selected - that is, if it is a comment
    the user has just posted
  }
  tag "comments:field:if_selected" do |tag|
    tag.expand if tag.locals.comment == tag.locals.page.selected_comment
  end

  desc %{
    Renders the contained elements if the comment has been approved
  }
  tag "comments:field:if_approved" do |tag|
    tag.expand if tag.locals.comment.approved?
  end

  desc %{
    Renders the contained elements if the comment has not been approved
  }
  tag "comments:field:unless_approved" do |tag|
    tag.expand unless tag.locals.comment.approved?
  end

  desc %{
    Renders a Gravatar URL for the author of the comment.
  }
  tag "comments:field:gravatar_url" do |tag|
    email = tag.locals.comment.author_email
    size = tag.attr['size']
    format = tag.attr['format']
    rating = tag.attr['rating']
    default = tag.attr['default']
    md5 = Digest::MD5.hexdigest(email)
    returning "http://www.gravatar.com/avatar/#{md5}" do |url|
      url << ".#{format.downcase}" if format
      if size || rating || default
        attrs = []
        attrs << "s=#{size}" if size
        attrs << "d=#{default}" if default
        attrs << "r=#{rating.downcase}" if rating
        url << "?#{attrs.join('&')}"
      end
    end
  end

  desc %{
    Renders a comment form.

    *Usage:*
    <r:comment:form [class="comments" id="comment_form"]>...</r:comment:form>
  }
  tag "comments:form" do |tag|
    attrs = tag.attr.symbolize_keys
    html_class, html_id = attrs[:class], attrs[:id]
    r = %Q{ <form action="#{tag.locals.page.url}#{'comments' unless Radiant::Config['comments.post_to_page?']}}
      r << %Q{##{html_id}} unless html_id.blank?
    r << %{" method="post" } #comlpete the quotes for the action
      r << %{ id="#{html_id}" } unless html_id.blank?
      r << %{ class="#{html_class}" } unless html_class.blank?
    r << '>' #close the form element
    r <<  tag.expand
    r << %{</form>}
    r
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
  
  desc %{
    Renders the nested content if the posted comment was found unsure by Mollom.
  }
  tag "comments:if_unsure" do |tag|
    tag.expand if tag.locals.page.captcha_url
  end
  desc %{
    Renders the nested content unless the posted comment was found unsure by Mollom.
  }
  tag "comments:unless_unsure" do |tag|
    tag.expand unless tag.locals.page.captcha_url
  end
  
  desc %{
    Renders a CAPTCHA if the posted comment was found unsure by Mollom.
    
    *Usage:*
    <r:comments:mollom_captcha [label="hey.. are you even human?"] />
  }
  tag "comments:mollom_captcha" do |tag|
    if tag.locals.page.captcha_url
      url = tag.locals.page.captcha_url
      text = tag.attr['label']||I18n.t('message_unsure')
      return %{
        <div id="captcha_form">
          <form method="post" action="#{tag.locals.page.url}comments/solve_captcha">
          <label for="captcha_answer">#{text}</label>
          <img src="#{url}" alt="Mollom image CAPTCHA" /><br />
          <input type="text" name="captcha_answer" />
          <input type="hidden" name="comment_mollom_id" value="#{tag.locals.page.comment_mollom_id}"/>
          <input type="submit" />
          </form>
        </div>
      }
    end
  end
  
  desc %{
    Only expands if the posted comment is thought to be spam.
    
    *Usage:*
    <pre><code><r:comments:if_spam message="we don't like your spamming around here.." /></code></pre>
    or use a double tag to send your own content:
    <pre><code><r:comments:if_spam>&lt;p class="error">...&lt;/p></r:comments:if_spam></code></pre>
  }
  tag "comments:if_spam" do |tag|
    if tag.locals.page.posted_comment_is_spam == true
      if tag.double?
        tag.expand
      else
        tag.attr["message"]
      end
    end
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
    value = attrs.delete(:value)
    name = attrs.delete(:name)
    r =  %{<select name="comment[#{name}]"}
    unless attrs.empty?
      r << " "
      r << attrs.map {|k,v| %Q(#{k}="#{v}") }.join(" ")
    end
    r << %{>}

    TextFilter.descendants.each do |filter|

      r << %{<option value="#{filter.filter_name}"}
      r << %{ selected="selected"} if value == filter.filter_name
      r << %{>#{filter.filter_name}</option>}

    end

    r << %{</select>}
  end

  desc %{Prints the number of comments. }
  tag "comments:count" do |tag|
    tag.locals.page.comments.approved.count
  end
  
  
  tag "recent_comments" do |tag|
    tag.expand
  end
  
  desc %{Returns the last [limit] comments throughout the site.
    
    *Usage:*
    <pre><code><r:recent_comments:each [limit="10"]>...</r:recent_comments:each></code></pre>
    }
  tag "recent_comments:each" do |tag|
    limit = tag.attr['limit'] || 10
    comments = Comment.approved.recent.all(:limit => limit)
    result = []
    comments.each_with_index do |comment, index|
      tag.locals.comment = comment
      tag.locals.index = index
      tag.locals.page = comment.page
      result << tag.expand
    end
    result
  end
  
  desc %{
    Use this to prevent spam bots from filling your site with spam.
    
    *Usage:*
    <pre><code>What day comes after Monday? <r:comments:spam_answer_tag answer="Tuesday" /></code></pre>
  }
  tag "comments:spam_answer_tag" do |tag|
      attrs = tag.attr.symbolize_keys
      valid_spam_answer = attrs[:answer] || 'hemidemisemiquaver'
      md5_answer = Digest::MD5.hexdigest(valid_spam_answer.to_slug)
      r = %{<input type="text" id="comment_spam_answer" name="comment[spam_answer]"}
      r << %{ class="#{attrs[:class]}"} if attrs[:class]
      if value = (tag.locals.page.last_comment ? tag.locals.page.last_comment.send(:spam_answer) : '')
        r << %{ value="#{value}" }
      end
      r << %{ />}
      r << %{<input type="hidden" name="comment[valid_spam_answer]" value="#{md5_answer}" />}
  end

  desc %{
    Render the contained elements if using the simple spam filter.
  }
  tag "if_comments_simple_spam_filter_enabled" do |tag|
    tag.expand if Comment.simple_spam_filter_enabled?
  end

  desc %{
    Render the contained elements unless using the simple spam filter.
  }
  tag "unless_comments_simple_spam_filter_enabled" do |tag|
    tag.expand unless Comment.simple_spam_filter_enabled?
  end

end

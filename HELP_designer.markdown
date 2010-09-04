## Spam-blocking Questions

By default you'll have a Snippet called 'comment\_spam\_block' which will provide a way to
ask your site commenters a simple question.

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
    
The snippet takes advantage of the built-in Radius tags `r:random` and `r:option` to provide a random 
and less predictable selection of questions for commenters.

Be sure to alter this snippet for your site!

## Displaying comments and the comment form

In your site layout (or another appropriate place) use the following code to display your comment form:

    <r:snippet name="comments" />
    
### After comments are posted...

Relative urls will *not* work on comment pages if they fail validation, since the page gets re-rendered
at a (probably) different level of the hierarchy. Always use absolute urls and you won't have any issues.
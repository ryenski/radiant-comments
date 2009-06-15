You have the capability to use 3 different methods of spam blocking with this extension.

1. Logic CAPTCHA (asking a question a spambot would not know)
2. [Akismet](http://akismet.com/) 
3. [Mollom](http://mollom.com/)

## Spam Blocking

By default, you will have sample questions that you may ask of your visitors. These questions are difficult
to easily interpret by robots that may crawl your site looking to leave spam. See your Snippet
'comment\_spam\_block' for examples of this.

You will need to use the spam\_answer\_tag in your comment forms to present these questions to the user.

If you wish disable this simple spam protection mechanism, you can do so using the `require_simple_spam_filter`
config key, e.g. Radiant::Config['comments.require_simple_spam_filter'] = false

To enable the Akismet protection, get yourself an account at http://akismet.com/personal/ for your personal
blog or at http://akismet.com/commercial/ for your commercial sites. Then set your personal key and url
in the Radiant::Config.

For example:

    Radiant::Config['comments.akismet_key'] = "6a009ca6ab4e"
    Radiant::Config['comments.akismet_url'] = "yoursite.com"

To enable Mollom protection, get yourself an account at http://mollom.com/user/register, add your site and
set the public and private key pair in the Radiant::Config.

    Radiant::Config['comments.mollom_privatekey'] = "deadbeef012345"
    Radiant::Config['comments.mollom_publickey'] = "c00fee012345"

If both services are configured, this plugin will use the Akismet service. Unset the akismet_key if you
want to use Mollom.

## Exporting Data

To customize the CSV fields you can add an initializer like this:

    Comment.class_eval do
      def export_columns(format = nil)
        %w[approved? author author_email content referrer]
      end
    end
    
## Viewing comments

You may set the per page number of comments in the Radiant configuration options:
    
    Radiant::Config['comments.per_page'] = 100
    
By default, the number of comments per page is 50.
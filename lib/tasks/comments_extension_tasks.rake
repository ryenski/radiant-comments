namespace :radiant do
  namespace :extensions do
    namespace :comments do
      
      desc "Single task to install and update the Comments extension"
      task :install => [:environment, :initialize, :migrate, :update]
      
      desc "Runs the migration of the Comments extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          CommentsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          CommentsExtension.migrator.migrate
        end
      end
      
      desc "Copies the public files to your public directory"
      task :update => :environment do
        FileUtils.cp CommentsExtension.root + "/public/images/admin/accept.png", RAILS_ROOT + "/public/images/admin"
      end
      
      desc "Generates the initializer for comment sanitizing"
      task :initialize do
        sanitizer_path = File.join(Rails.root, 'config', 'initializers', 'sanitizer.rb')
        if !File.exist?(sanitizer_path)
          do_task :forced_initialize
        end
      end
      
      desc "Regenerates the initializer for comment sanitizing if it does not yet exist"
      task :forced_initialize do
        sanitizer_path = File.join(Rails.root, 'config', 'initializers', 'sanitizer.rb')
        File.open(sanitizer_path,'w+') do |file|
          file.write string = <<FILE
# The Comments Extension uses this option to clean out unwanted elements from the comments.
# The example output for each option is the result of sanitization for this text:
#
# '<b><a href="http://foo.com/">foo</a></b><img src="http://foo.com/bar.jpg" />'
#
# Uncomment one of the options below to choose your preference. By default, RELAXED is used.
# For more information about your options, please see the Sanitize documentation:
# http://rgrove.github.com/sanitize/

COMMENT_SANITIZER_OPTION = 
  Sanitize::Config::RELAXED # Gives you '<b><a href="http://foo.com/">foo</a></b><img src="http://foo.com/bar.jpg" />'
  # Sanitize::Config::BASIC # Results in '<b><a href="http://foo.com/" rel="nofollow">foo</a></b>'
  # Sanitize::Config::RESTRICTED # This results in '<b>foo</b>'
  
  # Or you may create your own sanitization rules. Uncomment all the lines below and edit them as you need.
  # {:elements => ['a', 'span'],
  #  :attributes => {'a' => ['href', 'title'], 'span' => ['class']},
  #  :protocols => {'a' => {'href' => ['http', 'https', 'mailto']}}}
FILE
        end
      end
      puts "Comment sanitization settings may be found in config/initializers/sanitizer.rb"
    end
  end
end
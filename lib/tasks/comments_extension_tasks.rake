namespace :radiant do
  namespace :extensions do
    namespace :comments do
      
      desc "Runs the migration of the Comments extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          CommentsExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          CommentsExtension.migrator.migrate
        end
      end
      
      task :update => :environment do
        FileUtils.cp CommentsExtension.root + "/public/images/admin/accept.png", RAILS_ROOT + "/public/images/admin"
      end
      
    end
  end
end
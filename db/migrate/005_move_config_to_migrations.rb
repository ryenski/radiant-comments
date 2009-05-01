class MoveConfigToMigrations < ActiveRecord::Migration
  def self.up
    if Radiant::Config.table_exists?
      { 'notification' => 'false',
        'notification_from' => '',
        'notification_to' => '',
        'notification_site_name' => '',
        'notify_creator' => 'true',
        'notify_updater' => 'false',
        'akismet_key' => '',
        'akismet_url' => '',
        'mollom_privatekey' => '',
        'mollom_publickey' => '',
        'filters_enabled' => 'true',
      }.each{|k,v| Radiant::Config.create(:key => "comments.#{k}", :value => v) unless Radiant::Config["comments.#{k}"]}
    end
  end
  
  def self.down
    # not necessary
  end
end
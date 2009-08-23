class AddPreferenceForSimpleSpamcheck < ActiveRecord::Migration
  def self.up
    if Radiant::Config['comments.simple_spam_filter_required?'].blank?
      Radiant::Config.create(:key => 'comments.simple_spam_filter_required?', :value => true)
    end
  end
  
  def self.down
    # not necessary
  end
end


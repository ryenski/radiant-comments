class MollomSpamFilter < SpamFilter
  def message
    'Protected by <a href="http://mollom.com">Mollom</a>'
  end
  
  def configured?
    !Radiant::Config['comments.mollom_privatekey'].blank? &&
    !Radiant::Config['comments.mollom_publickey'].blank?
  end

  def valid?(comment)
    approved?(comment)
  rescue SpamFilter::Unsure
  end
  
  def approved?(comment)
    mollom.key_ok? && ham?(comment)
  rescue Mollom::Error
    false
  end

  def spam!(comment)
    begin
      if mollom.key_ok? and !comment.mollom_id.empty?
        mollom.send_feedback :session_id => comment.mollom_id, :feedback => 'spam'
      end
    rescue Mollom::Error => e
      raise Comment::AntispamWarning.new(e.to_s)
    end
  end

  def mollom
    @mollom ||= Mollom.new(:private_key => Radiant::Config['comments.mollom_privatekey'], :public_key => Radiant::Config['comments.mollom_publickey']).tap do |m|
      unless Rails.cache.read('MOLLOM_SERVER_CACHE').blank?
        m.server_list = YAML::load(Rails.cache.read('MOLLOM_SERVER_CACHE'))
      end
    end
  end

  def mollom_response(comment)
    mollom.check_content(
      :author_name => comment.author,            # author name
      :author_mail => comment.author_email,         # author email
      :author_url => comment.author_url,           # author url
      :post_body => comment.content,              # comment text
      :author_ip => comment.author_ip
      )
  end
  
  private
  
  def ham?(comment)
    response = mollom_response(comment)
    save_mollom_servers
    response.ham?
  end
  
  def save_mollom_servers
    Rails.cache.write('MOLLOM_SERVER_CACHE', mollom.server_list.to_yaml) if mollom.key_ok?
  rescue Mollom::Error #TODO: something with this error...
  end
end
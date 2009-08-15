class SpamFilter
  include Simpleton
  def self.[](key)
    self.descendants.find {|klass| klass.name =~ /^#{key.camelize}/ }
  end
  
  def approved?(comment)
    raise NotImplementedError, "spam filter subclasses should implement this method"
  end
  
  def spam!(comment)
    # This is only implemented in filters that accept feedback like Mollom
  end
  
  def configured?
    false
  end
  
  # By default, let comments save to the database.  Then they can be approved
  # manually or auto-approved by the filter.
  def valid?(comment)
    true
  end
  
  class Spam < ::StandardError; end
end
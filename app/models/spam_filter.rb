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
  
  class Spam < ::StandardError; end
end
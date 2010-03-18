unless Array.instance_methods.include?('without')
  class Array
    def without(object)
      self.dup.tap do |new_array|
        new_array.delete(object)
      end
    end
  end
end

class SpamFilter
  include Simpleton
  
  def message
    raise NotImplementedError, 'spam filter subclasses should implement this method'
  end
  
  def select
    # Make sure Simple filter comes last, as a fallback
    filters = SpamFilter.descendants.without(SimpleSpamFilter) << SimpleSpamFilter
    filters.find {|filter| filter.try(:configured?) }
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
  class Unsure < ::StandardError; end
end
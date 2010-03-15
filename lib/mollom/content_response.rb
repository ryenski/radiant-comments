class Mollom
  class ContentResponse
    attr_reader :session_id, :quality

    Unknown = 0
    Ham  = 1
    Spam = 2
    Unsure = 3

    # This class should only be initialized from within the +check_content+ command.
    def initialize(hash)
      @spam_response = hash["spam"]
      @session_id = hash["session_id"]
      @quality = hash["quality"]
    end

    # Is the content Spam?
    def spam?
      @spam_response == Spam
    end

    # Is the content Ham?
    def ham?
      @spam_response == Ham
    end

    # is Mollom unsure about the content?
    def unsure?
      @spam_response == Unsure
    end

    # is the content unknown?
    def unknown?
      @spam_response == Unknown
    end

    # Returns 'unknown', 'ham', 'unsure' or 'spam', depending on what the content is.
    def to_s
      case @spam_response
      when Unknown 	then 'unknown'
      when Ham 		then 'ham'
      when Unsure 	then 'unsure'
      when Spam 	then 'spam'
      end
    end
  end
end
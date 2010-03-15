class Mollom
  module ApiCompatibility
    def self.included base
      base.class_eval do
        alias checkContent check_content
        alias getImageCaptcha image_captcha
        alias getAudioCaptcha audio_captcha
        alias checkCaptcha valid_captcha?
        alias verifyKey key_ok?
        alias getStatistics statistics
        alias sendFeedback send_feedback
        alias detectLanguage language_for
      end
    end
  end
end
require File.dirname(__FILE__) + '/../test_helper'

class CustomTagsExtensionTest < Test::Unit::TestCase
  
  # Replace this with your real tests.
  def test_this_extension
    #flunk
  end
  
  def test_initialization
    #assert_equal RADIANT_ROOT + '/vendor/extensions/custom_tags', CustomTagsExtension.root
    #assert_equal 'Custom Tags', CustomTagsExtension.extension_name
  end
  
  def test_anonymous_can_post_comment
  end
  
  def test_should_validate_presence_of_name_body_and_email
  end
  
  def test_page_has_many_comments
  end
  
  def test_deleting_page_should_delete_comments
  end
  
end

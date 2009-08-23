module Admin::CommentsHelper
  def link_or_span_unless_current(text, url, options={})
    link_to_unless_current(text,url, options) do
      content_tag(:span, text)
    end
  end
end
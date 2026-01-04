# frozen_string_literal: true

module GroupingsHelper
  def ul_tag_for(grouping_class)
    result = if grouping_class == Tag
               %(<ul id="taglist" class="tags">)
             elsif grouping_class == Category
               %(<ul class="categorylist">)
             else
               '<ul>'
             end
    result.html_safe
  end
end

# frozen_string_literal: true

class ERB
  module Util
    def html_escape(s)
      silence_warnings do
        s = s.to_s
        if s.html_safe?
          s
        else
          s.gsub(/[&"'><]/n) { |special| HTML_ESCAPE[special] }.html_safe
        end
      end
    end
  end
end

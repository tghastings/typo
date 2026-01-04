# frozen_string_literal: true

class Class # :nodoc:
  def class_inheritable_option(sym, default_value = nil)
    # Use class_attribute for Rails 4+ compatibility
    class_attribute sym, instance_accessor: true, instance_predicate: false, default: default_value

    # Override the class method to allow setting without =
    class_eval <<-EOS, __FILE__, __LINE__ + 1
      def self.#{sym}(value=nil)
        if !value.nil?
          self.#{sym} = value
        else
          super()
        end
      end
    EOS
  end
end

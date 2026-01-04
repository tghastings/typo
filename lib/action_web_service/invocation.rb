# frozen_string_literal: true

module ActionWebService # :nodoc:
  module Invocation # :nodoc:
    class InvocationError < ActionWebService::ActionWebServiceError # :nodoc:
    end

    def self.included(base) # :nodoc:
      base.extend(ClassMethods)
      base.send(:include, ActionWebService::Invocation::InstanceMethods)
    end

    # Invocation interceptors provide a means to execute custom code before
    # and after method invocations on ActionWebService::Base objects.
    #
    # When running in _Direct_ dispatching mode, ActionController filters
    # should be used for this functionality instead.
    #
    # The semantics of invocation interceptors are the same as ActionController
    # filters, and accept the same parameters and options.
    #
    # A _before_ interceptor can also cancel execution by returning +false+,
    # or returning a <tt>[false, "cancel reason"]</tt> array if it wishes to supply
    # a reason for canceling the request.
    #
    # === Example
    #
    #   class CustomService < ActionWebService::Base
    #     before_invocation :intercept_add, :only => [:add]
    #
    #     def add(a, b)
    #       a + b
    #     end
    #
    #     private
    #       def intercept_add
    #         return [false, "permission denied"] # cancel it
    #       end
    #   end
    #
    # Options:
    # [<tt>:except</tt>]  A list of methods for which the interceptor will NOT be called
    # [<tt>:only</tt>]    A list of methods for which the interceptor WILL be called
    module ClassMethods
      # Appends the given +interceptors+ to be called
      # _before_ method invocation.
      def append_before_invocation(*interceptors, &block)
        conditions = extract_conditions!(interceptors)
        interceptors << block if block_given?
        add_interception_conditions(interceptors, conditions)
        append_interceptors_to_chain('before', interceptors)
      end

      # Prepends the given +interceptors+ to be called
      # _before_ method invocation.
      def prepend_before_invocation(*interceptors, &block)
        conditions = extract_conditions!(interceptors)
        interceptors << block if block_given?
        add_interception_conditions(interceptors, conditions)
        prepend_interceptors_to_chain('before', interceptors)
      end

      alias before_invocation append_before_invocation

      # Appends the given +interceptors+ to be called
      # _after_ method invocation.
      def append_after_invocation(*interceptors, &block)
        conditions = extract_conditions!(interceptors)
        interceptors << block if block_given?
        add_interception_conditions(interceptors, conditions)
        append_interceptors_to_chain('after', interceptors)
      end

      # Prepends the given +interceptors+ to be called
      # _after_ method invocation.
      def prepend_after_invocation(*interceptors, &block)
        conditions = extract_conditions!(interceptors)
        interceptors << block if block_given?
        add_interception_conditions(interceptors, conditions)
        prepend_interceptors_to_chain('after', interceptors)
      end

      alias after_invocation append_after_invocation

      def before_invocation_interceptors # :nodoc:
        read_inheritable_attribute('before_invocation_interceptors')
      end

      def after_invocation_interceptors # :nodoc:
        read_inheritable_attribute('after_invocation_interceptors')
      end

      def included_intercepted_methods # :nodoc:
        read_inheritable_attribute('included_intercepted_methods') || {}
      end

      def excluded_intercepted_methods # :nodoc:
        read_inheritable_attribute('excluded_intercepted_methods') || {}
      end

      private

      def append_interceptors_to_chain(condition, interceptors)
        write_inheritable_array("#{condition}_invocation_interceptors", interceptors)
      end

      def prepend_interceptors_to_chain(condition, interceptors)
        interceptors += read_inheritable_attribute("#{condition}_invocation_interceptors")
        write_inheritable_attribute("#{condition}_invocation_interceptors", interceptors)
      end

      def extract_conditions!(interceptors)
        return nil unless interceptors.last.is_a? Hash

        interceptors.pop
      end

      def add_interception_conditions(interceptors, conditions)
        return unless conditions

        included = conditions[:only]
        excluded = conditions[:except]
        if included
          write_inheritable_hash('included_intercepted_methods',
                                 condition_hash(interceptors, included)) && return
        end

        write_inheritable_hash('excluded_intercepted_methods', condition_hash(interceptors, excluded)) if excluded
      end

      def condition_hash(interceptors, *methods)
        interceptors.inject({}) do |hash, interceptor|
          hash.merge(interceptor => methods.flatten.map(&:to_s))
        end
      end
    end

    # Module to prepend for interception functionality
    module Interception # :nodoc:
      def perform_invocation(method_name, params, &)
        return if before_invocation(method_name, params, &) == false

        return_value = super(method_name, params)
        after_invocation(method_name, params, return_value)
        return_value
      end
    end

    module InstanceMethods # :nodoc:
      def self.included(base)
        base.prepend(Interception)
      end

      def perform_invocation(method_name, params)
        send(method_name, *params)
      end

      def before_invocation(name, args, &)
        call_interceptors(self.class.before_invocation_interceptors, [name, args], &)
      end

      def after_invocation(name, args, result)
        call_interceptors(self.class.after_invocation_interceptors, [name, args, result])
      end

      private

      def call_interceptors(interceptors, interceptor_args, &block)
        return unless interceptors && !interceptors.empty?

        interceptors.each do |interceptor|
          next if method_exempted?(interceptor, interceptor_args[0].to_s)

          result = if interceptor.is_a?(Symbol)
                     send(interceptor, *interceptor_args)
                   elsif interceptor_block?(interceptor)
                     interceptor.call(self, *interceptor_args)
                   elsif interceptor_class?(interceptor)
                     interceptor.intercept(self, *interceptor_args)
                   else
                     raise(
                       InvocationError,
                       'Interceptors need to be either a symbol, proc/method, or a class implementing a static intercept method'
                     )
                   end
          reason = nil
          if result.is_a?(Array)
            reason = result[1] if result[1]
            result = result[0]
          end
          if result == false
            block.call(reason) if block && reason
            return false
          end
        end
      end

      def interceptor_block?(interceptor)
        interceptor.respond_to?('call') && [3, -1].include?(interceptor.arity)
      end

      def interceptor_class?(interceptor)
        interceptor.respond_to?('intercept')
      end

      def method_exempted?(interceptor, method_name)
        if self.class.included_intercepted_methods[interceptor]
          !self.class.included_intercepted_methods[interceptor].include?(method_name)
        elsif self.class.excluded_intercepted_methods[interceptor]
          self.class.excluded_intercepted_methods[interceptor].include?(method_name)
        end
      end
    end
  end
end

# frozen_string_literal: true

module TypoPlugins
  # Deprecated?
  def plugin_public_action(action)
    @@plugin_public_actions ||= []
    @@plugin_public_actions.push action
  end

  # Deprecated?
  def plugin_public_actions
    @@plugin_public_actions
  end

  # Deprecated?
  def plugin_description(desc)
    define_singleton_method(:description) { desc }
  end

  # Deprecated?
  def plugin_display_name(name)
    define_singleton_method(:display_name) { name }
  end

  unless defined?(Keeper) # Something in rails double require this module. Prevent that to keep @@registered integrity
    class Keeper
      KINDS = %i[avatar textfilter].freeze
      @@registered = {}

      class << self
        def available_plugins(kind = nil)
          return @@registered.inspect unless kind
          raise ArgumentError, "#{kind} is not part of available plugins targets (#{KINDS.map(&:to_s).join(',')})" unless KINDS.include?(kind)

          @@registered ? @@registered[kind] : nil
        end

        def register(klass)
          unless KINDS.include?(klass.kind)
            raise ArgumentError,
                  "#{klass.kind} is not part of available plugins targets (#{KINDS.map(&:to_s).join(',')})"
          end

          @@registered[klass.kind] ||= []
          @@registered[klass.kind] << klass
          Rails.logger.debug("TypoPlugins: just registered plugin #{@@registered[klass.kind]} for #{klass.kind.inspect} target.")
          @@registered[klass.kind]
        end
      end

      private

      def initialize
        raise 'No instance allowed.'
      end
    end
  end

  class Base
    class << self
      attr_accessor :name, :description
      attr_reader   :registered

      def kind
        :void
      end
    end

    def initialize(h = {})
      h = h.dup
      kind = h.delete(:kind)
      raise ArgumentError, "#{kind} is not part of available plugins targets (#{KINDS.map(&:to_s).join(',')})" unless KINDS.include?(kind)

      @kind = kind
      return if h.empty?

      raise ArgumentError,
            "Too many keys in TypoPlugins::Base hash: I don't know what to do with your remainder: #{h.inspect}"
    end
  end
end

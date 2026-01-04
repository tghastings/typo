# frozen_string_literal: true

module Stateful
  class State
    def initialize(model)
      @model = model
    end

    def to_s
      self.class.to_s.demodulize
    end

    def exit_hook(_target_state)
      ::Rails.logger.debug("#{model} leaving state #{self}")
    end

    def enter_hook
      ::Rails.logger.debug("#{model} entering state #{self}")
    end

    def method_missing(predicate, *)
      if predicate.to_s.last == '?'
        self.class.to_s.demodulize.underscore == predicate.to_s.chop
      elsif block_given?
        super { |*block_args| yield(*block_args) }
      else
        super
      end
    end

    def ==(other)
      self.class == other.class
    end

    def hash
      self.class.hash
    end

    private

    attr_reader :model
  end

  def self.included(base)
    base.extend ClassMethods
  end

  module ClassMethods
    def has_state(field, options = {})
      options.assert_valid_keys(:valid_states, :handles, :initial_state)

      unless (states = options[:valid_states])
        raise 'You must specify at least one state'
      end

      states        = states.collect(&:to_sym)

      delegations   = Set.new(options[:handles]) + states.collect { |value| "#{value}?" }

      initial_state = options[:initial_state] || states.first

      state_writer_method(field, states, initial_state)
      state_reader_method(field, states, initial_state)
      state_reload_method(field)

      delegations.each do |value|
        delegate value, to: field
      end
    end

    def state_reader_method(name, states, initial_state)
      module_eval <<-END_METH, __FILE__, __LINE__ + 1
        def #{name}(force_reload = false)
          if @#{name}_obj.nil? || force_reload
            memento = read_attribute(#{name.inspect}) || #{initial_state.inspect}
            unless #{states.inspect}.include? memento.to_sym
              raise "Invalid state: \#{memento} in the database."
            end
            @#{name}_obj = self.class.class_eval(memento.to_s.classify).new(self)
          end
          @#{name}_obj
        end
      END_METH
    end

    def state_writer_method(name, states, _initial_state)
      module_eval <<-END_METH, __FILE__, __LINE__ + 1
        def #{name}=(state)
          case state
          when Symbol
            set_#{name}_from_symbol state
          when String
            set_#{name}_from_symbol state.to_sym
          else
            raise "You must set the state with a symbol or a string"
          end
        end

        def set_#{name}_from_symbol(memento)
          unless #{states.inspect}.include?(memento)
            raise "Invalid state: " + memento
          end
          self[:#{name}] = memento.to_s
          new_state = self.class.class_eval(memento.to_s.classify).new(self)
          @#{name}_obj.exit_hook(new_state) if @#{name}_obj
          @#{name}_obj = new_state
          @#{name}_obj.enter_hook
          @#{name}_obj
        end
      END_METH
    end

    def state_reload_method(name)
      module_eval <<-END_METH, __FILE__, __LINE__ + 1
        def reload(*args)
          @#{name}_obj = nil
          super
        end
      END_METH
    end
  end
end

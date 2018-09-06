# frozen_string_literal: true

module RspecInContext
  class NoContextFound < StandardError; end
  Context = Struct.new(:block, :owner)
  module InContext
    class << self
      def included(base)
        base.extend ClassMethods
      end

      def contexts
        @contexts ||= ActiveSupport::HashWithIndifferentAccess.new
      end

      def add_context(context_name, owner = nil, &block)
        contexts[context_name] = Context.new(block, owner)
      end

      def find_context(context_name)
        contexts[context_name] ||
          (raise NoContextFound, "No context found with name #{context_name}")
      end

      def remove_context(current_class)
        contexts.delete_if{ |_, context| context.owner == current_class }
      end

      def outside_define_context(context_name, &block)
        InContext.add_context(context_name, &block)
      end
    end

    module ClassMethods
      def in_context(context_name, *args, &block)
        Thread.current[:test_block] = block
        context(context_name.to_s) do
          instance_exec(*args, &InContext.find_context(context_name).block)
        end
      end

      def execute_tests
        instance_exec(&Thread.current[:test_block]) if Thread.current[:test_block]
      end
      alias_method :instanciate_context, :execute_tests

      def define_context(context_name, &block)
        instance_exec do
          InContext.add_context(context_name, hooks.instance_variable_get(:@owner), &block)
        end
      end
    end
  end
end

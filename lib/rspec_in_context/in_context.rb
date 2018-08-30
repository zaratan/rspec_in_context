# frozen_string_literal: true

module RspecInContext
  module InContext
    class << self
      def included(base)
        base.extend ClassMethods
      end

      def contexts
        @contexts ||= ActiveSupport::HashWithIndifferentAccess.new
      end

      def add_context(context_name, &block)
        contexts[context_name] = block
      end

      def find_context(context_name)
        contexts[context_name] || raise("No context found with name #{context_name}")
      end

      def define_context(context_name, &block)
        InContext.add_context(context_name, &block)
      end
    end

    module ClassMethods
      def in_context(context_name, *args, &block)
        Thread.current[:test_block] = block
        instance_exec(*args, &InContext.find_context(context_name))
      end

      def execute_tests
        instance_exec(&Thread.current[:test_block]) if Thread.current[:test_block]
      end
      alias_method :instanciate_context, :execute_tests

      def define_context(context_name, &block)
        InContext.add_context(context_name, &block)
      end
    end
  end
end

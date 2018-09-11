# frozen_string_literal: true

module RspecInContext
  class NoContextFound < StandardError; end
  Context = Struct.new(:block, :owner, :name, :namespace)
  module InContext
    GLOBAL_CONTEXT = :global_context
    class << self
      def included(base)
        base.extend ClassMethods
      end

      def contexts
        @contexts ||= HashWithIndifferentAccess.new { |hash, key| hash[key] = HashWithIndifferentAccess.new }
      end

      def add_context(context_name, owner = nil, namespace = nil, &block)
        namespace ||= GLOBAL_CONTEXT
        contexts[namespace][context_name] = Context.new(block, owner, context_name, namespace)
      end

      def find_context(context_name, namespace = nil)
        if namespace&.present?
          contexts[namespace][context_name]
        else
          contexts[GLOBAL_CONTEXT][context_name] || find_context_in_any_namespace(context_name)
        end ||
          (raise NoContextFound, "No context found with name #{context_name}")
      end

      def find_context_in_any_namespace(context_name)
        valid_namespace = contexts.find{ |_, namespaced_contexts| namespaced_contexts[context_name] }&.last
        valid_namespace[context_name] if valid_namespace
      end

      def remove_context(current_class)
        contexts.each do |_, namespaced_contexts|
          namespaced_contexts.delete_if{ |_, context| context.owner == current_class }
        end
      end

      def outside_define_context(context_name, namespace, &block)
        InContext.add_context(context_name, nil, namespace, &block)
      end
    end

    module ClassMethods
      def in_context(context_name, *args, namespace: nil, ns: nil, &block)
        namespace ||= ns
        Thread.current[:test_block] = block
        context(context_name.to_s) do
          instance_exec(*args, &InContext.find_context(context_name, namespace).block)
        end
      end

      def execute_tests
        instance_exec(&Thread.current[:test_block]) if Thread.current[:test_block]
      end
      alias_method :instanciate_context, :execute_tests

      def define_context(context_name, namespace: nil, ns: nil, &block)
        namespace ||= ns
        instance_exec do
          InContext.add_context(context_name, hooks.instance_variable_get(:@owner), namespace, &block)
        end
      end
    end
  end
end

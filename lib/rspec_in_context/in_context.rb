# frozen_string_literal: true

# Base module
module RspecInContext
  # Error type when no context is find from its name (and eventualy namespace)
  class NoContextFound < StandardError; end

  # Context struct
  # @attr [Proc] block what will be executed in the test context
  # @attr [Class] owner current rspec context class. This will be used to know where a define_context has been defined
  # @attr [String | Symbol] name represent the name by which the context can be find.
  # @attr [String | Symbol] namespace namespace for context names to avoid collisions
  # @attr [Boolean] silent does the in_context should wrap itself into a context with its name upon execution
  Context = Struct.new(:block, :owner, :name, :namespace, :silent)

  # Main module containing almost every methods
  module InContext
    # Name of the Global context
    GLOBAL_CONTEXT = :global_context
    class << self
      # Hook for easier inclusion of the gem in RSpec
      # @api private
      def included(base)
        base.extend ClassMethods
      end

      # Contexts container + creation
      # @api private
      def contexts
        @contexts ||= HashWithIndifferentAccess.new { |hash, key| hash[key] = HashWithIndifferentAccess.new }
      end

      # Meta method to add a new context
      # @api private
      #
      # @note Will warn if a context is overriden
      def add_context(context_name, owner = nil, namespace = nil, silent = true, &block) # rubocop:disable Style/OptionalBooleanParameter
        namespace ||= GLOBAL_CONTEXT
        warn("Overriding an existing context: #{context_name}@#{namespace}") if contexts[namespace][context_name]
        contexts[namespace][context_name] = Context.new(block, owner, context_name, namespace, silent)
      end

      # Find a context.
      # @api private
      def find_context(context_name, namespace = nil)
        if namespace&.present?
          contexts[namespace][context_name]
        else
          contexts[GLOBAL_CONTEXT][context_name] || find_context_in_any_namespace(context_name)
        end ||
          (raise NoContextFound, "No context found with name #{context_name}")
      end

      # Look into every namespace to find the context
      # @api private
      def find_context_in_any_namespace(context_name)
        valid_namespace = contexts.find{ |_, namespaced_contexts| namespaced_contexts[context_name] }&.last
        valid_namespace[context_name] if valid_namespace
      end

      # @api private
      # Delete a context
      def remove_context(current_class)
        contexts.each_value do |namespaced_contexts|
          namespaced_contexts.delete_if{ |_, context| context.owner == current_class }
        end
      end

      # @api private
      # Define a context from outside a RSpec.describe block
      def outside_define_context(context_name, namespace, silent, &block)
        InContext.add_context(context_name, nil, namespace, silent, &block)
      end
    end

    # This module define the methods that will be available for the end user inside RSpec tests
    module ClassMethods
      # Use a context and inject its content at this place in the code
      #
      # @param [String, Symbol] context_name The context namespace
      # @param [*Any] args Any arg to be passed down to the injected context
      # @param [String, Symbol] namespace namespace name where to look for the context
      # @param [String, Symbol] ns Alias for :namespace
      # @param block Content that will be re-injected (see #execute_tests)
      def in_context(context_name, *args, namespace: nil, ns: nil, &block)
        namespace ||= ns
        Thread.current[:test_block] = block
        context_to_exec = InContext.find_context(context_name, namespace)
        if context_to_exec.silent
          return instance_exec(*args, &context_to_exec.block)
        end

        context(context_name.to_s) do
          instance_exec(*args, &context_to_exec.block)
        end
      end

      # Used in context definition
      # Place where you want to re-inject code passed in argument of in_context
      #
      # For convenience and readability, a `instanciate_context` alias have been defined
      # (for more examples look at tests)
      def execute_tests
        instance_exec(&Thread.current[:test_block]) if Thread.current[:test_block]
      end
      alias_method :instanciate_context, :execute_tests

      # Let you define a context that can be reused later
      #
      # @param context_name [String, Symbol] The name of the context that will be re-used later
      # @param namespace [String, Symbol] namespace name where the context will be stored.
      #   It helps reducing colisions when you define "global" contexts
      # @param ns [String, Symbol] Alias of namespace
      # @param block [Proc] Contain the code that will be injected with #in_context later
      # @param silent [Boolean] Does the in_context should wrap itself into a context block with its name
      # @param print_context [Boolean] Reverse alias of silent
      #
      # @note contexts are scoped to the block they are defined in.
      def define_context(context_name, namespace: nil, ns: nil, silent: true, print_context: nil, &block)
        namespace ||= ns
        silent = print_context.nil? ? silent : !print_context
        instance_exec do
          InContext.add_context(context_name, hooks.instance_variable_get(:@owner), namespace, silent, &block)
        end
      end
    end
  end
end

# Base module
module RspecInContext
  # Base error class for all gem errors
  class Error < StandardError
  end

  # Error type when no context is found from its name (and eventually namespace)
  class NoContextFound < Error
  end

  # Error type when define_context is called without a block
  class MissingDefinitionBlock < ArgumentError
  end

  # Error type when context_name is nil or empty
  class InvalidContextName < ArgumentError
  end

  # Error type when multiple namespaces contain a context with the same name
  class AmbiguousContextName < Error
  end

  # Context struct
  # @attr [Proc] block what will be executed in the test context
  # @attr [Class] owner current rspec context class. This will be used to know where a define_context has been defined
  # @attr [String | Symbol] name represent the name by which the context can be found.
  # @attr [String | Symbol] namespace namespace for context names to avoid collisions
  # @attr [Boolean] silent does the in_context wrap itself into a context with its name or an anonymous context
  Context = Struct.new(:block, :owner, :name, :namespace, :silent)

  # Main module containing almost every methods
  module InContext
    # Name of the Global context
    GLOBAL_CONTEXT = :global_context
    # Mutex protecting @contexts for thread-safety (e.g. parallel_tests in thread mode)
    @contexts_mutex = Mutex.new

    class << self
      # Hook for easier inclusion of the gem in RSpec
      # @api private
      def included(base)
        base.extend ClassMethods
      end

      # Contexts container + creation
      # Keys are normalized to strings so symbols and strings are interchangeable.
      # @api private
      def contexts
        @contexts_mutex.synchronize do
          @contexts ||= Hash.new { |hash, key| hash[key.to_s] = {} }
        end
      end

      # Remove all stored contexts (both scoped and global).
      # Useful for memory cleanup in long-running test suites with
      # dynamically generated contexts.
      def clear_all_contexts!
        @contexts_mutex.synchronize { @contexts = nil }
      end

      # Meta method to add a new context
      # @api private
      #
      # @note Will warn if a context is overridden
      # @raise [InvalidContextName] if context_name is nil or empty
      # @raise [MissingDefinitionBlock] if no block is provided
      def add_context(
        context_name,
        owner = nil,
        namespace = nil,
        silent = true,
        &block
      )
        if context_name.nil? ||
             (context_name.respond_to?(:empty?) && context_name.empty?)
          raise InvalidContextName, "context_name cannot be nil or empty"
        end
        unless block
          raise MissingDefinitionBlock, "define_context requires a block"
        end

        namespace ||= GLOBAL_CONTEXT
        ns_key = namespace.to_s
        name_key = context_name.to_s
        if contexts.dig(ns_key, name_key)
          warn("Overriding an existing context: #{context_name}@#{namespace}")
        end
        contexts[ns_key][name_key] = Context.new(
          block,
          owner,
          context_name,
          namespace,
          silent,
        )
      end

      # Find a context.
      # @api private
      # @raise [NoContextFound] if no context is found
      # @raise [AmbiguousContextName] if multiple namespaces contain the same context name
      def find_context(context_name, namespace = nil)
        name_key = context_name.to_s
        result =
          if namespace && !namespace.to_s.empty?
            contexts.dig(namespace.to_s, name_key)
          else
            find_context_across_all_namespaces(name_key)
          end
        result ||
          (raise NoContextFound, "No context found with name #{context_name}")
      end

      # Look into every namespace to find the context
      # Uses dig to avoid auto-vivifying empty namespace entries
      # @api private
      # @raise [AmbiguousContextName] if multiple namespaces contain the same context name
      def find_context_across_all_namespaces(name_key)
        matching_namespaces =
          contexts.select do |_, namespaced_contexts|
            namespaced_contexts[name_key]
          end
        if matching_namespaces.size > 1
          namespace_names = matching_namespaces.keys.join(", ")
          raise AmbiguousContextName,
                "Context '#{name_key}' exists in multiple namespaces (#{namespace_names}). " \
                  "Please specify a namespace."
        end
        matching_namespaces.values.first&.[](name_key)
      end

      # @api private
      # Delete a context
      def remove_context(current_class)
        contexts.each_value do |namespaced_contexts|
          namespaced_contexts.delete_if do |_, context|
            context.owner == current_class
          end
        end
      end

      # @api private
      # Define a context from outside a RSpec.describe block
      def outside_define_context(context_name, namespace, silent, &)
        InContext.add_context(context_name, nil, namespace, silent, &)
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
        context_to_exec = InContext.find_context(context_name, namespace)
        Thread.current[:test_block_stack] ||= []
        Thread.current[:test_block_stack].push(block)
        begin
          if context_to_exec.silent
            context { instance_exec(*args, &context_to_exec.block) }
          else
            context(
              context_name.to_s,
            ) { instance_exec(*args, &context_to_exec.block) }
          end
        ensure
          Thread.current[:test_block_stack].pop
        end
      end

      # Used in context definition
      # Place where you want to re-inject code passed in argument of in_context
      # (for more examples look at tests)
      def execute_tests
        current_block = Thread.current[:test_block_stack]&.last
        instance_exec(&current_block) if current_block
      end
      alias instantiate_context execute_tests

      # @deprecated Use {#instantiate_context} or {#execute_tests} instead
      def instanciate_context
        warn(
          "DEPRECATION: `instanciate_context` is deprecated due to a typo. " \
            "Use `instantiate_context` or `execute_tests` instead.",
          uplevel: 1,
        )
        execute_tests
      end

      # Let you define a context that can be reused later
      #
      # @param context_name [String, Symbol] The name of the context that will be re-used later
      # @param namespace [String, Symbol] namespace name where the context will be stored.
      #   It helps reducing collisions when you define "global" contexts
      # @param ns [String, Symbol] Alias of namespace
      # @param block [Proc] Contain the code that will be injected with #in_context later
      # @param silent [Boolean] Does the in_context wrap itself into a context with its name or an anonymous context
      # @param print_context [Boolean] Reverse alias of silent
      #
      # @note contexts are scoped to the block they are defined in.
      def define_context(
        context_name,
        namespace: nil,
        ns: nil,
        silent: true,
        print_context: nil,
        &
      )
        namespace ||= ns
        silent = !print_context unless print_context.nil?
        InContext.add_context(
          context_name,
          hooks.instance_variable_get(:@owner),
          namespace,
          silent,
          &
        )
      end
    end
  end
end

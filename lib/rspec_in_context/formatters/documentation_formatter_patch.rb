# frozen_string_literal: true

module RspecInContext
  module Formatters
    # Prepended onto RSpec::Core::Formatters::DocumentationFormatter to
    # hide the anonymous context wrappers that silent in_context creates.
    #
    # Without this patch, each silent in_context adds a blank line and an
    # extra indentation level to --format documentation output.
    module DocumentationFormatterPatch
      def example_group_started(notification)
        group = notification.group
        # Double check: metadata + empty description.
        # RSpec metadata inherits to children, but notification.group.description
        # returns the group's OWN description (not the inherited/concatenated one).
        # So named sub-contexts (non-empty description) pass through to super normally.
        if group.metadata[:rspec_in_context_silent] == true &&
             group.description.strip.empty?
          return
        end

        super
      end

      def example_group_finished(notification)
        group = notification.group
        if group.metadata[:rspec_in_context_silent] == true &&
             group.description.strip.empty?
          return
        end

        super
      end
    end
  end
end

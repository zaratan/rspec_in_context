# frozen_string_literal: true

require 'active_support/all'
require "rspec_in_context/version"
require "rspec_in_context/in_context"
require "rspec_in_context/context_management"

# Main wrapping module
module RspecInContext
  # @api private
  # Inclusion convenience of the gem in RSpec
  def self.included(base)
    base.include(RspecInContext::InContext)
  end
end

# RSpec
module RSpec
  # Allows you to define contexts outside of RSpec.describe blocks
  #
  # @param name [String, Symbol] Name of the defined context
  # @param namespace [String, Symbol] Namespace where to store your context
  # @param ns Alias of namespace
  # @param silent [Boolean] Does the in_context should wrap itself into a context block with its name
  # @param print_context [Boolean] Reverse alias of silent
  # @param block [Proc] code that will be injected later
  def self.define_context(name, namespace: nil, ns: nil, silent: true, print_context: nil, &block)
    namespace ||= ns
    silent = print_context.nil? ? silent : !print_context
    RspecInContext::InContext.outside_define_context(name, namespace, silent, &block)
  end
end

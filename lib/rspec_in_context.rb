# frozen_string_literal: true

require 'active_support/all'
require "rspec_in_context/version"
require "rspec_in_context/in_context"
require "rspec_in_context/context_management"

module RspecInContext
  def self.included(base)
    base.include(RspecInContext::InContext)
  end
end

module RSpec
  def self.define_context(name, namespace: nil, ns: nil, &block)
    namespace ||= ns
    RspecInContext::InContext.outside_define_context(name, namespace, &block)
  end
end

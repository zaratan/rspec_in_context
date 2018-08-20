# frozen_string_literal: true

require 'active_support/all'
require "rspec_in_context/version"
require "rspec_in_context/in_context"

module RspecInContext
  def self.included(base)
    base.include(RspecInContext::InContext)
  end
end

module RSpec
  def self.define_context(name, &block)
    RspecInContext::InContext.define_context(name, &block)
  end
end

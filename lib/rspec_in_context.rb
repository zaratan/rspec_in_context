# frozen_string_literal: true

require "rspec_in_context/version"
require "rspec_in_context/in_context"

module RspecInContext
  def self.included(base)
    base.include(RspecInContext::InContext)
  end
end

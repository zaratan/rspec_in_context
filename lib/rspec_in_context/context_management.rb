# frozen_string_literal: true

module RspecInContext
  module ContextManagement
    def subclass(parent, description, args, registration_collection, &example_group_block)
      subclass = super
      RspecInContext::InContext.remove_context(subclass)
      subclass
    end
  end
end

module RSpec
  module Core
    class ExampleGroup
      class << self
        prepend RspecInContext::ContextManagement
      end
    end
  end
end

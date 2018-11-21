# frozen_string_literal: true

module RspecInContext
  # Allow context to be scoped inside a block
  module ContextManagement
    # @api private
    # prepending a RSpec method so we can know when a describe/context block finish
    # its reading
    def subclass(parent, description, args, registration_collection, &example_group_block)
      subclass = super
      RspecInContext::InContext.remove_context(subclass)
      subclass
    end
  end
end

module RSpec
  # Core
  module Core
    # ExampleGroup
    class ExampleGroup
      class << self
        # allow context management to work
        prepend RspecInContext::ContextManagement
      end
    end
  end
end

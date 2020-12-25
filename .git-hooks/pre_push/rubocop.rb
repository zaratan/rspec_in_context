# frozen_string_literal: true

module Overcommit
  module Hook
    module PrePush
      # Runs `rubocop` on every files.
      class Rubocop < Base
        def run
          result = execute(['rubocop', '-P'])
          return :pass if result.success?

          output = result.stdout + result.stderr
          [:fail, output]
        end
      end
    end
  end
end

require "open3"
require "tempfile"

RSpec.describe RspecInContext::Formatters::DocumentationFormatterPatch do
  def run_spec_with_documentation_formatter(spec_content)
    Tempfile.create(["formatter_test", ".rb"]) do |f|
      f.write(spec_content)
      f.flush

      stdout, stderr, status = Open3.capture3(
        { "DISABLE_SIMPLECOV" => "1" },
        "bundle", "exec", "rspec", f.path,
        "--format", "documentation",
        "--order", "defined",
        "--no-color",
        "--options", File::NULL
      )
      [stdout, stderr, status]
    end
  end

  describe "silent in_context output" do
    it "does not produce a blank line or extra indentation for silent in_context" do
      spec_content = <<~RUBY
        require_relative "#{File.expand_path("../../lib/rspec_in_context", __dir__)}"

        RSpec.configure do |config|
          config.include RspecInContext
        end

        RSpec.describe "SilentFormatterTest" do
          define_context "my silent context" do
            it "works inside silent context" do
              expect(true).to be(true)
            end
          end

          in_context "my silent context"
        end
      RUBY

      stdout, _stderr, status = run_spec_with_documentation_formatter(spec_content)
      expect(status.success?).to be(true), "Spec failed: #{stdout}"

      lines = stdout.lines.map(&:rstrip)
      # Find the describe line
      describe_idx = lines.index { |l| l.include?("SilentFormatterTest") }
      expect(describe_idx).not_to be_nil

      # The example should be directly under the describe, indented by 2 spaces (not 4)
      example_line = lines.find { |l| l.include?("works inside silent context") }
      expect(example_line).not_to be_nil
      expect(example_line).to match(/^  works inside silent context/)

      # No blank line between the describe and the example
      relevant_lines = lines[describe_idx..].reject(&:empty?)
      expect(relevant_lines[0]).to include("SilentFormatterTest")
      expect(relevant_lines[1]).to include("works inside silent context")
    end
  end

  describe "non-silent in_context output" do
    it "still prints the context name for non-silent in_context" do
      spec_content = <<~RUBY
        require_relative "#{File.expand_path("../../lib/rspec_in_context", __dir__)}"

        RSpec.configure do |config|
          config.include RspecInContext
        end

        RSpec.describe "NonSilentFormatterTest" do
          define_context "visible context", silent: false do
            it "works inside non-silent context" do
              expect(true).to be(true)
            end
          end

          in_context "visible context"
        end
      RUBY

      stdout, _stderr, status = run_spec_with_documentation_formatter(spec_content)
      expect(status.success?).to be(true), "Spec failed: #{stdout}"

      lines = stdout.lines.map(&:rstrip)
      expect(lines.any? { |l| l.include?("visible context") }).to be(true)
      expect(lines.any? { |l| l.include?("works inside non-silent context") }).to be(true)
    end
  end

  describe "named sub-context inside silent in_context" do
    it "prints named sub-contexts normally" do
      spec_content = <<~RUBY
        require_relative "#{File.expand_path("../../lib/rspec_in_context", __dir__)}"

        RSpec.configure do |config|
          config.include RspecInContext
        end

        RSpec.describe "SubContextFormatterTest" do
          define_context "with sub-context" do
            context "when nested" do
              it "shows nested context name" do
                expect(true).to be(true)
              end
            end
          end

          in_context "with sub-context"
        end
      RUBY

      stdout, _stderr, status = run_spec_with_documentation_formatter(spec_content)
      expect(status.success?).to be(true), "Spec failed: #{stdout}"

      lines = stdout.lines.map(&:rstrip)
      expect(lines.any? { |l| l.include?("when nested") }).to be(true)
      expect(lines.any? { |l| l.include?("shows nested context name") }).to be(true)
    end
  end

  describe "nested silent in_context calls" do
    it "handles nested silent contexts without extra indentation" do
      spec_content = <<~RUBY
        require_relative "#{File.expand_path("../../lib/rspec_in_context", __dir__)}"

        RSpec.configure do |config|
          config.include RspecInContext
        end

        RSpec.describe "NestedSilentTest" do
          define_context "inner silent" do
            it "deeply nested example" do
              expect(true).to be(true)
            end
          end

          define_context "outer silent" do
            in_context "inner silent"
          end

          in_context "outer silent"
        end
      RUBY

      stdout, _stderr, status = run_spec_with_documentation_formatter(spec_content)
      expect(status.success?).to be(true), "Spec failed: #{stdout}"

      lines = stdout.lines.map(&:rstrip)
      example_line = lines.find { |l| l.include?("deeply nested example") }
      expect(example_line).not_to be_nil
      # Should be indented 2 spaces (directly under describe), not 4 or 6
      expect(example_line).to match(/^  deeply nested example/)
    end
  end

  describe "mixed silent and non-silent in_context" do
    it "only prints non-silent context names" do
      spec_content = <<~RUBY
        require_relative "#{File.expand_path("../../lib/rspec_in_context", __dir__)}"

        RSpec.configure do |config|
          config.include RspecInContext
        end

        RSpec.describe "MixedSilentTest" do
          define_context "visible wrapper", silent: false do
            it "inside visible" do
              expect(true).to be(true)
            end
          end

          define_context "silent wrapper around visible" do
            in_context "visible wrapper"
          end

          in_context "silent wrapper around visible"
        end
      RUBY

      stdout, _stderr, status = run_spec_with_documentation_formatter(spec_content)
      expect(status.success?).to be(true), "Spec failed: #{stdout}"

      lines = stdout.lines.map(&:rstrip)
      # The non-silent "visible wrapper" should appear
      expect(lines.any? { |l| l.include?("visible wrapper") }).to be(true)
      # The example should be inside it
      expect(lines.any? { |l| l.include?("inside visible") }).to be(true)
    end
  end

  describe "patch module structure" do
    it "is prepended on DocumentationFormatter" do
      expect(
        RSpec::Core::Formatters::DocumentationFormatter.ancestors
      ).to include(RspecInContext::Formatters::DocumentationFormatterPatch)
    end
  end

  describe "unit tests for patch methods" do
    let(:output) { StringIO.new }
    let(:formatter) { RSpec::Core::Formatters::DocumentationFormatter.new(output) }

    def notification_for(description: "", metadata: {})
      group = double("ExampleGroup", description: description, metadata: metadata)
      double("GroupNotification", group: group)
    end

    describe "#example_group_started" do
      it "skips silent contexts with empty description" do
        notification = notification_for(
          description: "",
          metadata: { rspec_in_context_silent: true }
        )
        formatter.example_group_started(notification)
        expect(output.string).to eq("")
      end

      it "does not skip groups without the metadata" do
        notification = notification_for(description: "", metadata: {})
        formatter.example_group_started(notification)
        expect(output.string).not_to eq("")
      end

      it "does not skip groups with metadata but non-empty description" do
        notification = notification_for(
          description: "some context",
          metadata: { rspec_in_context_silent: true }
        )
        formatter.example_group_started(notification)
        expect(output.string).to include("some context")
      end
    end

    describe "#example_group_finished" do
      it "skips silent contexts with empty description" do
        notification = notification_for(
          description: "",
          metadata: { rspec_in_context_silent: true }
        )
        # Start a non-silent group first to have @group_level > 0
        normal_notification = notification_for(
          description: "normal",
          metadata: {}
        )
        formatter.example_group_started(normal_notification)
        level_before = formatter.instance_variable_get(:@group_level)

        formatter.example_group_finished(notification)
        level_after = formatter.instance_variable_get(:@group_level)

        expect(level_after).to eq(level_before)
      end
    end
  end
end

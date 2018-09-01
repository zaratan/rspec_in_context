# frozen_string_literal: true

RSpec.define_context "outside in_context" do
  it "works for outside context" do
    expect(true).to be_truthy
  end
end

describe RspecInContext::InContext do
  define_context "inside in_context" do
    it "works for inside context" do
      expect(true).to be_truthy
    end
  end

  define_context :with_symbol do
    it "works both with and without symbols" do
      expect(true).to be_truthy
    end
  end

  define_context "with test block" do
    it "doesn't find unexistant variable" do
      expect(defined?(new_var)).to be_falsy
    end

    context "with new variable" do
      let(:new_var) { true }

      execute_tests
    end
  end

  define_context "with instanciate block" do
    it "doesn't find unexistant variable" do
      expect(defined?(new_var)).to be_falsy
    end

    context "with variable instanciated" do
      instanciate_context

      it "works with another variable" do
        expect(another_var).to eq(:value)
      end
    end
  end

  define_context "with argument" do |name|
    it "doesn't find #{name}" do
      expect(defined?(outside_var)).to be_falsy
    end

    context "with #{name}" do
      let(name) { true }

      execute_tests
    end
  end

  define_context :nested do
    context "with inside_var defined" do
      let(:inside_var) { true }

      it "works in nested in_context" do
        expect(outside_var).to eq(inside_var)
      end
    end
  end

  define_context "in_context in in_context" do
    in_context "with argument", :inside do
      it "works to use a in_context inside a define_context" do
        expect(inside).to be_truthy
      end
    end
  end

  describe "in_context calls" do
    in_context "outside in_context"
    in_context "inside in_context"
    in_context "with_symbol"

    in_context "with test block" do
      it "works with new_var" do
        expect(new_var).to be_truthy
      end
    end

    in_context "with instanciate block" do
      let(:another_var) { :value }
    end

    in_context "with argument", :outside_var do
      it "works with outside_var" do
        expect(outside_var).to be_truthy
      end

      in_context :nested
    end

    in_context "in_context in in_context"
  end
end

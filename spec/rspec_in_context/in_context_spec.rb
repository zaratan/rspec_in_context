# frozen_string_literal: true

RSpec.define_context "outside in_context" do
  it "works for outside context" do
    expect(true).to be_truthy
  end
end

describe RspecInContext do
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
    it "doesn't find poire" do
      expect(defined?(poire)).to be_falsy
    end

    context "with poire" do
      let(:poire) { true }

      execute_tests
    end
  end

  define_context "with instanciate block" do
    it "doesn't find poire" do
      expect(defined?(poire)).to be_falsy
    end

    context "with poire" do
      instanciate_context

      it "works with abricot" do
        expect(abricot).to eq(:poire)
      end
    end
  end

  define_context "with argument" do |name|
    it "doesn't find #{name}" do
      expect(defined?(poire)).to be_falsy
    end

    context "with #{name}" do
      let(name) { true }

      execute_tests
    end
  end

  define_context :nested do
    context "with poire" do
      let(:poire) { true }

      it "works in nested in_context" do
        expect(pomme).to eq(poire)
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
      it "works with poire" do
        expect(poire).to be_truthy
      end
    end

    in_context "with instanciate block" do
      let(:abricot) { :poire }
    end

    in_context "with argument", :pomme do
      it "works with pomme" do
        expect(pomme).to be_truthy
      end

      in_context :nested
    end

    in_context "in_context in in_context"
  end
end

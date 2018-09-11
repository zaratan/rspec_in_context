# frozen_string_literal: true

describe RspecInContext::ContextManagement do
  describe "within a describe block" do
    define_context "simple describe test" do
      it "is well scoped" do
        expect(true).to be_truthy
      end
    end

    in_context "simple describe test"

    context "within a sub context" do
      in_context "simple describe test"
    end

    describe "within a sub describe" do
      in_context "simple describe test"
    end
  end

  context "within a context block" do
    define_context "simple context test" do
      it "is well scoped" do
        expect(true).to be_truthy
      end
    end

    in_context "simple context test"

    context "within a sub context" do
      in_context "simple context test"
    end

    describe "within a sub describe" do
      in_context "simple context test"
    end

    test_inexisting_context "simple describe test"
  end

  test_inexisting_context "simple describe test", "using in_context in a child context"
  test_inexisting_context "simple context test", "using in_context in a child context"
end

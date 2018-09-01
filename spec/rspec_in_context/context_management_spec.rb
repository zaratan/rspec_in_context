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

    begin
      in_context "simple describe test"

      # If we get there the test has failed T_T
      describe "using in_context defined in a sibling context" do
        it "is well scoped" do
          expect(false).to be_truthy
        end
      end
    rescue RspecInContext::NoContextFound
      describe "using in_context defined in a sibling context" do
        it "is well scoped" do
          expect(true).to be_truthy
        end
      end
    end
  end

  begin
    in_context "simple describe test"

    # If we get there the test has failed T_T
    describe "using in_context defined in a child describe" do
      it "is well scoped" do
        expect(false).to be_truthy
      end
    end
  rescue RspecInContext::NoContextFound
    describe "using in_context defined in a sibling context" do
      it "is well scoped" do
        expect(true).to be_truthy
      end
    end
  end

  begin
    in_context "simple context test"

    # If we get there the test has failed T_T
    describe "using in_context defined in a child context" do
      it "is well scoped" do
        expect(false).to be_truthy
      end
    end
  rescue RspecInContext::NoContextFound
    describe "using in_context defined in a sibling context" do
      it "is well scoped" do
        expect(true).to be_truthy
      end
    end
  end
end

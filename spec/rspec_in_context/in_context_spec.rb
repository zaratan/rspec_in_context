# frozen_string_literal: true

RSpec.define_context 'outside in_context' do
  it 'works for outside context' do
    expect(true).to be_truthy
  end
end

RSpec.define_context 'outside namespaced', namespace: 'outside', silent: false do
  it 'works' do
    expect(true).to be_truthy
  end
end

RSpec.define_context 'outside short-namespaced', ns: 'outside', silent: false do
  it 'works' do
    expect(true).to be_truthy
  end
end

RSpec.define_context 'silent outside in_context' do
  $outside_in_context_class_silent = hooks.instance_variable_get(:@owner)

  it 'is silent by default' do
    expect($outside_in_context_class_silent.name.gsub(/::Anonymous(_\d)?/, '')).to eq($current_class.name)
  end
end

RSpec.define_context 'not silent outside in_context', silent: false do
  $outside_in_context_class_not_silent = hooks.instance_variable_get(:@owner)

  it 'is not silent' do
    expect($current_class).not_to eq($outside_in_context_class_not_silent)
  end
end

RSpec.define_context 'print_context outside in_context', print_context: true do
  $outside_in_context_class_print_context = hooks.instance_variable_get(:@owner)

  it 'is not silent' do
    expect($current_class).not_to eq($outside_in_context_class_print_context)
  end
end

describe RspecInContext::InContext do
  define_context 'inside in_context' do
    it 'works for inside context' do
      expect(true).to be_truthy
    end
  end

  define_context :with_symbol do
    it 'works both with and without symbols' do
      expect(true).to be_truthy
    end
  end

  define_context 'with test block' do
    it "doesn't find unexistant variable" do
      expect(defined?(new_var)).to be_falsy
    end

    context 'with new variable' do
      let(:new_var) { true }

      execute_tests
    end
  end

  define_context 'with instanciate block' do
    it "doesn't find unexistant variable" do
      expect(defined?(new_var)).to be_falsy
    end

    context 'with variable instanciated' do
      instanciate_context

      it 'works with another variable' do
        expect(another_var).to eq(:value)
      end
    end
  end

  define_context 'with argument' do |name|
    it "doesn't find #{name}" do
      expect(defined?(outside_var)).to be_falsy
    end

    context "with #{name}" do
      let(name) { true }

      execute_tests
    end
  end

  define_context :nested do
    context 'with inside_var defined' do
      let(:inside_var) { true }

      it 'works in nested in_context' do
        expect(outside_var).to eq(inside_var)
      end
    end
  end

  define_context 'in_context in in_context' do
    in_context 'with argument', :inside do
      it 'works to use a in_context inside a define_context' do
        expect(inside).to be_truthy
      end
    end
  end

  describe 'overriding an existing context' do
    before do
      expect(RspecInContext::InContext).to receive(:warn)
    end

    RSpec.define_context(:oustide_context) {}

    it 'warns' do
      RSpec.define_context(:oustide_context)
    end
  end

  describe 'in_context calls' do
    in_context 'outside in_context'
    in_context 'inside in_context'
    in_context 'with_symbol'

    in_context 'with test block' do
      it 'works with new_var' do
        expect(new_var).to be_truthy
      end
    end

    in_context 'with instanciate block' do
      let(:another_var) { :value }
    end

    in_context 'with argument', :outside_var do
      it 'works with outside_var' do
        expect(outside_var).to be_truthy
      end

      in_context :nested
    end

    in_context 'in_context in in_context'
  end

  describe 'silent and print_context options' do
    $current_class = hooks.instance_variable_get(:@owner)
    after(:all) do
      $current_class = nil
      $in_context_class_silent = nil
      $in_context_class_not_silent = nil
      $in_context_class_print_context = nil
      $outside_in_context_class_not_silent = nil
      $outside_in_context_class_print_context = nil
      $outside_in_context_class_silent = nil
    end

    define_context 'silent context' do
      $in_context_class_silent = hooks.instance_variable_get(:@owner)

      it 'is silent by default' do
        expect($current_class.name).to eq($in_context_class_silent.name.gsub(/::Anonymous(_\d)?/, ''))
      end
    end

    define_context 'not silent context', silent: false do
      $in_context_class_not_silent = hooks.instance_variable_get(:@owner)

      it 'is not silent' do
        expect($current_class).not_to eq($in_context_class_not_silent)
      end
    end

    define_context 'print_context context', print_context: true do
      $in_context_class_print_context = hooks.instance_variable_get(:@owner)

      it 'is not silent' do
        expect($current_class).not_to eq($in_context_class_print_context)
      end
    end

    in_context 'silent context'
    in_context 'not silent context'
    in_context 'print_context context'
    in_context 'silent outside in_context'
    in_context 'not silent outside in_context'
    in_context 'print_context outside in_context'
  end

  describe 'namespacing' do
    in_context 'outside namespaced'
    in_context 'outside namespaced', namespace: :outside
    in_context 'outside namespaced', ns: 'outside'
    in_context 'outside short-namespaced', ns: :outside
    test_inexisting_context 'outside namespaced', namespace: :not_exist

    define_context 'inside namespaced', namespace: :inside, silent: false do
      it 'works' do
        expect(true).to be_truthy
      end
    end

    define_context :inside, ns: :inside, silent: false do
      it 'works' do
        expect(true).to be_truthy
      end
    end

    define_context 'inside namespaced', ns: :inside2, silent: false do
      it 'works' do
        expect(true).to be_truthy
      end
    end

    in_context 'inside namespaced'
    in_context 'inside namespaced', namespace: :inside
    in_context :inside, ns: :inside
    in_context 'inside namespaced', ns: :inside
    in_context 'inside namespaced', ns: :inside2
    test_inexisting_context 'inside namespaced', namespace: :not_exist
    describe 'context isolation still work' do
      define_context 'isolated namespaced', ns: :isolated, silent: false do
        it 'works' do
          expect(true).to be_truthy
        end
      end
      in_context 'isolated namespaced', ns: :isolated
      in_context :inside, ns: :inside
    end
    test_inexisting_context 'isolated namespaced'
    test_inexisting_context 'isolated namespaced', ns: :isolated
  end
end

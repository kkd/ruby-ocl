# frozen_string_literal: true

# spec/account_error_message_spec.rb
require 'spec_helper'

RSpec.describe Account do
  let(:owner) { Owner.new(4_000_000) }
  let(:account) { Account.new(owner) }

  before do
    account.limit = 200_000
    account.amount = 1_000_000
    account.validate_invariants!
  end

  describe 'rich error messages' do
    context 'when invariant fails' do
      it 'includes expected and actual values' do
        expect do
          account.limit = 12_345
        end.to raise_error(OCL::ConstraintViolationError) { |error|
          expect(error.message).to include('Expected 12345 to equal 200000')
        }
      end
    end

    context 'when precondition fails' do
      it 'includes expected and actual values' do
        expect do
          account.withdraw(-10_000)
        end.to raise_error(OCL::ConstraintViolationError) { |error|
          expect(error.message).to include('Expected -10000 to be positive')
        }
      end

      it 'includes expected and actual values when withdraw amount exceeds limit' do
        expect do
          account.withdraw(300_000)
        end.to raise_error(OCL::ConstraintViolationError) { |error|
          expect(error.message).to include('Expected 300000 to be less than or equal to 200000')
        }
      end
    end

    context 'when postcondition fails' do
      it 'includes expected and actual values' do
        # limitは200,000のままでOK
        account.instance_variable_set(:@amount, 10_000) # 残高だけ少なくする

        expect do
          account.withdraw(30_000)
        end.to raise_error(OCL::ConstraintViolationError) { |error|
          expect(error.message).to include('Expected -20000 to be greater than or equal to 0')
        }
      end
    end
  end
end

# frozen_string_literal: true

# spec/account_spec.rb
require 'spec_helper'
# require_relative 'support/account'  # supportに置いた新しいaccount.rb

RSpec.describe Account do
  let(:owner) { Owner.new(4_000_000) }
  let(:account) { Account.new(owner) }

  before do
    account.limit = 200_000
    account.amount = 1_000_000
    account.validate_invariants!
  end

  describe 'invariant IncomeInvariant' do
    it 'is valid with correct limit based on owner income' do
      expect do
        account.validate_invariants!
      end.not_to raise_error
    end

    it 'raises error if limit is invalid' do
      expect do
        account.limit = 12_345
      end.to raise_error(OCL::ConstraintViolationError) { |error|
        expect(error.message).to include('Expected 12345 to equal 200000')
      }
    end
  end

  describe 'precondition PositiveAndWithinLimit' do
    it 'allows withdraw if amount is positive and within limit' do
      expect do
        account.withdraw(50_000)
      end.not_to raise_error
    end

    it 'raises error when withdraw amount is negative' do
      expect do
        account.withdraw(-10_000)
      end.to raise_error(OCL::ConstraintViolationError) { |error|
        expect(error.message).to include('Expected -10000 to be positive')
      }
    end

    it 'raises error when withdraw amount exceeds limit' do
      expect do
        account.withdraw(300_000)
      end.to raise_error(OCL::ConstraintViolationError) { |error|
        expect(error.message).to include('Expected 300000 to be less than or equal to 200000')
      }
    end
  end

  describe 'postcondition AmountNonNegative' do
    it 'raises error when withdraw causes negative balance' do
      account.instance_variable_set(:@amount, 10_000) # 残高を少なくしておく
      expect do
        account.withdraw(20_000)
      end.to raise_error(OCL::ConstraintViolationError) { |error|
        expect(error.message).to include('Expected -10000 to be greater than or equal to 0')
      }
    end

    it 'does not raise error when balance stays non-negative' do
      expect do
        account.withdraw(100_000)
      end.not_to raise_error
    end
  end
end

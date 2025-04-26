# frozen_string_literal: true

require_relative '../../lib/ocl' # ✅ OCLモジュールを読み込む！

# spec/support/owner.rb

class Owner
  attr_accessor :income

  def initialize(income)
    @income = income
  end
end

class Account
  include OCL

  attr_accessor_with_invariant :limit
  attr_accessor_with_invariant :amount
  attr_accessor :owner

  def initialize(owner)
    @owner = owner
    @limit = 0
    @amount = 0
  end

  def withdraw(amount_to_withdraw)
    @amount -= amount_to_withdraw
  end
end

# --- OCL制約の設定 ---

# 所有者の収入に応じたlimit設定
Account.inv('IncomeInvariant') do |c|
  expected = c.owner.income < 5_000_000 ? 200_000 : (c.owner.income * 0.1).round
  c.expect(c.limit).to_be(expected)
end

# withdraw前に：引き出し額が正、かつ引き出し額 <= limit
Account.pre(:withdraw, 'PositiveAndWithinLimit') do |c, amount_to_withdraw|
  c.expect(amount_to_withdraw).to_be_positive
  c.expect(amount_to_withdraw).to_be_less_than_or_equal_to(c.limit)
end

# withdraw後に：amountがマイナスにならない
Account.post(:withdraw, 'AmountNonNegative') do |c, _result, _amount_to_withdraw|
  c.expect(c.amount).to_be_greater_than_or_equal_to(0)
end

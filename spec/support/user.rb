# frozen_string_literal: true

require_relative '../../lib/ocl' # ✅ OCLモジュールを読み込む！

class User
  include OCL

  attr_accessor_with_invariant :first_name, :last_name

  def initialize(first_name, last_name)
    @first_name = first_name
    @last_name = last_name
  end
end

# 派生属性 full_name を外部DSLで定義
User.derived(:full_name) do |c|
  "#{c.first_name} #{c.last_name}"
end

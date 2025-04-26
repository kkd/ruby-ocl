# OCL - Ruby向けオブジェクト制約言語

Rubyクラスにシンプルかつ拡張可能な制約チェック機能を提供します。  
**Invariant（不変条件）**、**Precondition（事前条件）**、**Postcondition（事後条件）**、**Derived Attributes（派生属性）** をサポートしています。

---

## 概要

OCL（Object Constraint Language）は、オブジェクト指向プログラミングにおける軽量な契約ベースのプログラミング手法をRubyに導入するものです。  
クラスに制約（Constraint）を定義することで、オブジェクトの状態を常に正しく保つことができます。

サポートしている制約の種類：

- **Invariant**（不変条件）：常に成立すべきオブジェクトの条件
- **Precondition**（事前条件）：メソッド実行前に満たすべき条件
- **Postcondition**（事後条件）：メソッド実行後に満たすべき条件
- **Derived Attribute**（派生属性）：他の属性から動的に算出される属性

---

## OCLとテストフレームワーク（RSpec、test-unit）の違い

OCL（不変条件、事前条件、事後条件、派生属性）による制約は、  
**プロダクションコード内で実行時にオブジェクトの整合性を検証**するためのものです。  
本番環境でもオブジェクトの健全性を保証します。

一方、RSpecやtest-unitなどのテストフレームワークは、  
**開発中に期待通りの振る舞いをしているか検証する**ために使用します。

| 項目           | OCL                                | RSpec / test-unit                 |
|----------------|------------------------------------|-----------------------------------|
| 使うタイミング | 実行時                              | 開発・テストフェーズ              |
| 検証対象       | オブジェクト内部の一貫性              | メソッドやAPIの振る舞い           |
| 失敗時の反応   | 即時Runtimeエラー（ValidationError） | テスト失敗レポート               |
| 使用方法       | クラス定義に制約を埋め込む              | 別途テストケースを書く           |

**両方組み合わせて使うことで、最高の品質を実現できます：**
- OCLはオブジェクト内部の健全性を実行時に保証
- RSpecはビジネスロジックが正しいかを開発中に保証

---

## 特徴

- ✅ 流れるようなDSL（ドメイン特化言語）による制約定義
- ✅ 実行時に即時検証
- ✅ 豊富でわかりやすいエラーメッセージ
- ✅ 最小限で依存なし
- ✅ どんなRubyプロジェクトにも簡単に組み込み可能

---

## インストール

Gemfileに追加：

```ruby
gem 'ocl'
```

または手動インストール：

```bash
gem install ocl
```

---

## 基本的な使い方

このライブラリは、簡潔なDSLを使って「制約」（invariant、precondition、postcondition、derived属性）を定義・検証することができます。

1. **OCLモジュールをinclude**します。
2. **Invariant**（不変条件）を定義します - オブジェクトが常に満たすべき条件。
3. **Precondition**（事前条件）を定義します - メソッドを呼び出す前に満たすべき条件。
4. **Postcondition**（事後条件）を定義します - メソッドを呼び出した後に満たすべき条件。
5. **Derived属性**を定義します - 値をその場で計算する動的な属性（インスタンス変数に保存されない）。

使用例：

```ruby
require 'ocl'
class Account
  include OCL

  attr_accessor_with_invariant :limit
  attr_accessor :amount
  attr_accessor :owner

  def initialize(owner)
    @owner = owner
    @limit = 0
    @amount = 0
  end

  def withdraw(amount)
    @amount -= amount
  end
end

# 制約を定義
Account.inv('IncomeInvariant') do |context|
  owner_income = context.owner.income
  expected_limit = owner_income < 5_000_000 ? 200_000 : (owner_income * 0.1).round
  context.expect(context.limit).to_be(expected_limit)
end

Account.pre(:withdraw, 'PositiveAndWithinLimit') do |context, amount|
  context.expect(amount).to_be_positive
  context.expect(amount).to_be_less_than_or_equal_to(context.limit)
end

Account.post(:withdraw, 'AmountNonNegative') do |context, _result, _amount|
  context.expect(context.amount).to_be_greater_than_or_equal_to(0)
end
```

### クラスを使用

```ruby
owner = Owner.new(4_000_000)
account = Account.new(owner)
account.limit = 200_000
account.withdraw(50_000)   # OK
account.withdraw(300_000)  # リミットを超えるのでValidationErrorが発生
```

いずれかの制約に違反した場合、自動的に OCL::ValidationError が発生します。


## バリデーションブロック記述時の注意

OCLで `invariant`、`precondition`、`postcondition` を定義する際は、  
**複数の`expect`を`&&`や`||`などの論理演算子で結合しないでください**。

必ず**それぞれ個別に`expect`を記述**してください。

✅ 正しい書き方：

```ruby
pre(:withdraw, 'PositiveAndWithinLimit') do |c, amount|
  c.expect(amount).to_be_positive
  c.expect(amount).to_be_less_than_or_equal_to(c.limit)
end
```

❌ 間違った書き方：

```ruby
pre(:withdraw, 'PositiveAndWithinLimit') do |c, amount|
  c.expect(amount).to_be_positive && c.expect(amount).to_be_less_than_or_equal_to(c.limit)
end
```

**理由:**  
OCLにおける`expect`は、true/falseを返すのではなく、内部に検証結果を記録するだけです。  
そのため、`&&`や`||`で結合してもバリデーションエラーは正しく検出されません。

必ず、各`expect`を個別に記述してください。

---

## 開発・テスト方法

リポジトリをクローン後：

```bash
bundle install
```

テストを実行：

```bash
rake
```
または

```bash
rspec
```

ローカルでgemをビルドしてインストール：

```bash
gem build ocl.gemspec
gem install ./ocl-0.1.0.gem
```

---

## 参考資料

- [OMG Object Constraint Language (OCL) Specification 2.4 (PDF)](https://www.omg.org/spec/OCL/2.4/PDF)

このgemは、OMGによるOCL仕様のうち、  
主にランタイムでの**Invariant**、**Precondition**、**Postcondition**、**Derived Attribute**に焦点を当ててRuby向けに最小実装しています。

---

## ライセンス

MIT License © 2025 Takeshi Kakeda